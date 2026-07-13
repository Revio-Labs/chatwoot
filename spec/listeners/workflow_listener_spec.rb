require 'rails_helper'

RSpec.describe WorkflowListener do
  let(:listener) { described_class.instance }
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :pending) }

  before { account.update!(workflows_enabled: true) }

  def event(data)
    instance_double(Events::Base, data: data)
  end

  describe '#conversation_created' do
    it 'enqueues an advance job when a live workflow exists for the inbox' do
      create(:workflow_definition, account: account, inbox: inbox, status: :live, trigger_type: :conversation_created)
      expect(Workflows::AdvanceJob).to receive(:perform_later).with(conversation.id)
      listener.conversation_created(event(conversation: conversation))
    end

    it 'does nothing without a live workflow' do
      expect(Workflows::AdvanceJob).not_to receive(:perform_later)
      listener.conversation_created(event(conversation: conversation))
    end
  end

  describe '#message_created' do
    it 'enqueues for an incoming message when an active execution exists' do
      definition = create(:workflow_definition, account: account, inbox: inbox)
      create(:workflow_execution, account: account, conversation: conversation, workflow_definition: definition, status: :active)
      message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)
      expect(Workflows::AdvanceJob).to receive(:perform_later).with(conversation.id, message.id)
      listener.message_created(event(message: message))
    end

    it 'ignores outgoing messages' do
      create(:workflow_execution, account: account, conversation: conversation,
                                  workflow_definition: create(:workflow_definition, account: account, inbox: inbox), status: :active)
      message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing)
      expect(Workflows::AdvanceJob).not_to receive(:perform_later)
      listener.message_created(event(message: message))
    end
  end
end
