require 'rails_helper'

RSpec.describe Workflows::RunnerService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact,
                          contact_inbox: contact_inbox, status: :pending)
  end
  let(:definition) { create(:workflow_definition, account: account, inbox: inbox) }

  def execution_for(flow, current_node_id: nil)
    create(:workflow_execution, account: account, conversation: conversation,
                                workflow_definition: definition, flow_snapshot: flow,
                                current_node_id: current_node_id)
  end

  def incoming(submitted_value: nil, content: nil)
    attrs = submitted_value ? { submitted_values: [{ 'title' => submitted_value, 'value' => submitted_value }] } : {}
    create(:message, account: account, inbox: inbox, conversation: conversation,
                     message_type: :incoming, content: content, content_attributes: attrs)
  end

  describe 'walking the flow' do
    let(:flow) do
      {
        'nodes' => [
          { 'id' => 'greet', 'type' => 'send_message', 'content' => 'Hello' },
          { 'id' => 'menu', 'type' => 'send_buttons', 'content' => 'Pick',
            'items' => [{ 'title' => 'A', 'value' => 'a' }] }
        ],
        'edges' => [{ 'from' => 'greet', 'to' => 'menu' }]
      }
    end

    it 'sends messages until it hits a wait node, then persists position' do
      execution = execution_for(flow)
      expect { described_class.new(execution: execution).perform }
        .to change { conversation.messages.outgoing.count }.by(2)

      execution.reload
      expect(execution).to be_active
      expect(execution.current_node_id).to eq('menu')
      expect(conversation.messages.where(content_type: 'input_select')).to exist
    end
  end

  describe 'button reply matching' do
    let(:flow) do
      {
        'nodes' => [
          { 'id' => 'menu', 'type' => 'send_buttons', 'content' => 'Pick', 'items' => [] },
          { 'id' => 'done', 'type' => 'resolve' }
        ],
        'edges' => [{ 'from' => 'menu', 'to' => 'done', 'match' => { 'type' => 'button', 'value' => 'a' } }]
      }
    end

    it 'advances along the matching button edge' do
      execution = execution_for(flow, current_node_id: 'menu')
      described_class.new(execution: execution).perform(message: incoming(submitted_value: 'a'))
      expect(conversation.reload).to be_resolved
      expect(execution.reload).to be_completed
    end

    it 'stays put when no edge matches the reply' do
      execution = execution_for(flow, current_node_id: 'menu')
      described_class.new(execution: execution).perform(message: incoming(submitted_value: 'zzz'))
      expect(execution.reload.current_node_id).to eq('menu')
      expect(execution).to be_active
    end
  end

  describe 'condition and fallback edges' do
    let(:flow) do
      {
        'nodes' => [
          { 'id' => 'branch', 'type' => 'branch' },
          { 'id' => 'au', 'type' => 'add_label', 'label' => 'au' },
          { 'id' => 'other', 'type' => 'add_label', 'label' => 'other' }
        ],
        'edges' => [
          { 'from' => 'branch', 'to' => 'au',
            'match' => { 'type' => 'condition',
                         'conditions' => [{ 'attribute_key' => 'market', 'scope' => 'contact',
                                            'filter_operator' => 'equal_to', 'values' => ['Australia'] }] } },
          { 'from' => 'branch', 'to' => 'other', 'match' => { 'type' => 'fallback' } }
        ]
      }
    end

    it 'follows the condition edge when it matches' do
      contact.update!(custom_attributes: { 'market' => 'Australia' })
      execution = execution_for(flow)
      described_class.new(execution: execution).perform
      expect(conversation.reload.label_list).to include('au')
    end

    it 'follows the fallback edge when the condition fails' do
      contact.update!(custom_attributes: { 'market' => 'Singapore' })
      execution = execution_for(flow)
      described_class.new(execution: execution).perform
      expect(conversation.reload.label_list).to include('other')
    end
  end

  describe 'action nodes' do
    it 'set_attribute writes a contact custom attribute' do
      flow = { 'nodes' => [{ 'id' => 'sa', 'type' => 'set_attribute', 'scope' => 'contact',
                             'key' => 'market', 'value' => 'Australia' }], 'edges' => [] }
      described_class.new(execution: execution_for(flow)).perform
      expect(contact.reload.custom_attributes['market']).to eq('Australia')
    end

    it 'resolve node resolves the conversation and completes the execution' do
      flow = { 'nodes' => [{ 'id' => 'r', 'type' => 'resolve' }], 'edges' => [] }
      execution = execution_for(flow)
      described_class.new(execution: execution).perform
      expect(conversation.reload).to be_resolved
      expect(execution.reload).to be_completed
    end
  end

  describe 'handoff_agent' do
    it 'opens the conversation via bot_handoff! and marks the execution handed_off' do
      flow = { 'nodes' => [{ 'id' => 'h', 'type' => 'handoff_agent' }], 'edges' => [] }
      execution = execution_for(flow)
      described_class.new(execution: execution).perform
      expect(conversation.reload).to be_open
      expect(conversation.waiting_since).to be_present
      expect(execution.reload).to be_handed_off
    end
  end

  describe 'handoff_workflow' do
    it 'completes the current execution and starts the target definition' do
      target = create(:workflow_definition, account: account, inbox: inbox, status: :live,
                                            flow: { 'nodes' => [{ 'id' => 'sub', 'type' => 'send_message', 'content' => 'Sub' }],
                                                    'edges' => [] })
      flow = { 'nodes' => [{ 'id' => 'ho', 'type' => 'handoff_workflow', 'workflow_definition_id' => target.id }],
               'edges' => [] }
      execution = execution_for(flow)
      described_class.new(execution: execution).perform

      expect(execution.reload).to be_completed
      expect(conversation.workflow_executions.where(workflow_definition: target)).to exist
    end
  end

  describe 'guards' do
    it 'does nothing when the conversation is not pending' do
      conversation.update!(status: :open)
      flow = { 'nodes' => [{ 'id' => 'g', 'type' => 'send_message', 'content' => 'x' }], 'edges' => [] }
      execution = execution_for(flow)
      expect { described_class.new(execution: execution).perform }
        .not_to(change { conversation.messages.count })
    end
  end

  describe 'inline ticket via send_form' do
    it 'creates a ticket from the submitted form values' do
      account.update!(tickets_enabled: true)
      ticket_type = create(:ticket_type, account: account, name: 'Damage')
      flow = {
        'nodes' => [
          { 'id' => 'form', 'type' => 'send_form', 'content' => 'Details',
            'ticket_type_id' => ticket_type.id, 'items' => [{ 'name' => 'plate' }] }
        ],
        'edges' => []
      }
      execution = execution_for(flow, current_node_id: 'form')
      message = create(:message, account: account, inbox: inbox, conversation: conversation,
                                 message_type: :incoming, content_type: :form,
                                 content_attributes: { items: [{ 'name' => 'plate' }],
                                                       submitted_values: [{ 'name' => 'plate', 'value' => 'ABC123' }] })

      expect { described_class.new(execution: execution).perform(message: message) }
        .to change(Ticket, :count).by(1)
      expect(Ticket.last.custom_attributes['plate']).to eq('ABC123')
    end
  end
end
