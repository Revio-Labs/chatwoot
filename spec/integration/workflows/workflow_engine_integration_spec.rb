require 'rails_helper'

# Integration: exercises the REAL wiring — event listener registration, the
# Redis-backed mutex job, the runner, and MessageBuilder — with a live DB and
# Redis, rather than mocked units. This is the layer that would have caught the
# "worker running the stock image without WorkflowListener" class of bug.
RSpec.describe 'Workflow engine integration' do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact,
                          contact_inbox: contact_inbox, status: :pending)
  end

  let(:flow) do
    {
      'nodes' => [
        { 'id' => 'welcome', 'type' => 'send_message', 'content' => 'Hi!' },
        { 'id' => 'menu', 'type' => 'send_buttons', 'content' => 'Pick',
          'items' => [{ 'title' => 'Damage', 'value' => 'damage' }] },
        { 'id' => 'done', 'type' => 'resolve' }
      ],
      'edges' => [
        { 'from' => 'welcome', 'to' => 'menu' },
        { 'from' => 'menu', 'to' => 'done', 'match' => { 'type' => 'button', 'value' => 'damage' } }
      ]
    }
  end

  before do
    account.update!(workflows_enabled: true)
    create(:workflow_definition, account: account, inbox: inbox, status: :live,
                                 trigger_type: :conversation_created, flow: flow)
  end

  def event(data)
    instance_double(Events::Base, data: data)
  end

  it 'registers the WorkflowListener in the async dispatcher' do
    listener_classes = AsyncDispatcher.new.listeners.map(&:class)
    expect(listener_classes).to include(WorkflowListener)
  end

  it 'runs listener -> AdvanceJob (real mutex) -> runner and sends the welcome + buttons' do
    perform_enqueued_jobs(only: Workflows::AdvanceJob) do
      WorkflowListener.instance.conversation_created(event(conversation: conversation))
    end

    conversation.reload
    expect(conversation.workflow_executions.active.count).to eq(1)
    expect(conversation.messages.outgoing.count).to eq(2)
    expect(conversation.messages.where(content_type: 'input_select')).to exist
    expect(conversation.workflow_executions.first.current_node_id).to eq('menu')
  end

  it 'advances to resolve when the customer taps a button (message.updated chain)' do
    perform_enqueued_jobs(only: Workflows::AdvanceJob) do
      WorkflowListener.instance.conversation_created(event(conversation: conversation))
    end
    buttons_message = conversation.messages.find_by(content_type: 'input_select')

    perform_enqueued_jobs(only: Workflows::AdvanceJob) do
      buttons_message.update!(
        content_attributes: buttons_message.content_attributes.merge(
          submitted_values: [{ 'title' => 'Damage', 'value' => 'damage' }]
        )
      )
      WorkflowListener.instance.message_updated(event(message: buttons_message))
    end

    expect(conversation.reload).to be_resolved
    expect(conversation.workflow_executions.first).to be_completed
  end

  it 'advances only once when the same reply is delivered twice (idempotency)' do
    perform_enqueued_jobs(only: Workflows::AdvanceJob) do
      WorkflowListener.instance.conversation_created(event(conversation: conversation))
    end
    buttons_message = conversation.messages.find_by(content_type: 'input_select')
    buttons_message.update!(
      content_attributes: buttons_message.content_attributes.merge(
        submitted_values: [{ 'title' => 'Damage', 'value' => 'damage' }]
      )
    )

    perform_enqueued_jobs(only: Workflows::AdvanceJob) do
      2.times { WorkflowListener.instance.message_updated(event(message: buttons_message)) }
    end

    expect(conversation.reload).to be_resolved
    expect(conversation.workflow_executions.completed.count).to eq(1)
  end

  it 'creates a ticket from an inline form submission through the chain' do
    account.update!(tickets_enabled: true)
    ticket_type = create(:ticket_type, account: account, name: 'Damage')
    form_flow = {
      'nodes' => [
        { 'id' => 'form', 'type' => 'send_form', 'content' => 'Details',
          'ticket_type_id' => ticket_type.id, 'items' => [{ 'name' => 'plate' }] }
      ],
      'edges' => []
    }
    execution = create(:workflow_execution, account: account, conversation: conversation,
                                            flow_snapshot: form_flow, current_node_id: 'form',
                                            workflow_definition: account.workflow_definitions.first)
    form_message = create(:message, account: account, inbox: inbox, conversation: conversation,
                                    message_type: :incoming, content_type: :form,
                                    content_attributes: { items: [{ 'name' => 'plate' }],
                                                          submitted_values: [{ 'name' => 'plate', 'value' => 'ABC123' }] })

    expect do
      perform_enqueued_jobs(only: Workflows::AdvanceJob) do
        WorkflowListener.instance.message_created(event(message: form_message))
      end
    end.to change(Ticket, :count).by(1)

    expect(Ticket.last.custom_attributes['plate']).to eq('ABC123')
    expect(execution.reload).not_to be_active
  end
end
