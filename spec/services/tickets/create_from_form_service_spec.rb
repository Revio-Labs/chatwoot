require 'rails_helper'

RSpec.describe Tickets::CreateFromFormService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:ticket_type) { create(:ticket_type, account: account, name: 'Damage') }

  describe '#perform' do
    it 'creates a ticket with attributes from submitted values and links the conversation' do
      ticket = described_class.new(
        conversation: conversation, ticket_type: ticket_type,
        submitted_values: [{ 'name' => 'plate', 'value' => 'ABC123' }]
      ).perform

      expect(ticket.ticket_type).to eq(ticket_type)
      expect(ticket.conversation).to eq(conversation)
      expect(ticket.custom_attributes).to eq('plate' => 'ABC123')
      expect(ticket.ticket_links.count).to eq(1)
    end
  end

  describe '.from_workflow_node' do
    let(:node) { { 'type' => 'send_form', 'ticket_type_id' => ticket_type.id } }
    let(:message) do
      create(:message, account: account, conversation: conversation, inbox: conversation.inbox,
                       message_type: :incoming, content_type: :form,
                       content_attributes: { items: [{ 'name' => 'plate' }],
                                             submitted_values: [{ 'name' => 'plate', 'value' => 'XYZ' }] })
    end

    it 'creates a ticket for a send_form node carrying a ticket_type_id' do
      expect { described_class.from_workflow_node(conversation, node, message) }
        .to change(Ticket, :count).by(1)
    end

    it 'no-ops for a node without a ticket_type_id' do
      expect { described_class.from_workflow_node(conversation, { 'type' => 'send_form' }, message) }
        .not_to change(Ticket, :count)
    end

    it 'no-ops for a non-form node' do
      expect { described_class.from_workflow_node(conversation, { 'type' => 'send_message' }, message) }
        .not_to change(Ticket, :count)
    end
  end
end
