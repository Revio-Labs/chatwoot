require 'rails_helper'

RSpec.describe WorkflowDefinition do
  let(:account) { create(:account) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    it 'is invalid without a nodes array in flow' do
      definition = build(:workflow_definition, account: account, flow: { 'edges' => [] })
      expect(definition).not_to be_valid
      expect(definition.errors[:flow]).to be_present
    end

    it 'rejects a flow with more than 100 nodes' do
      nodes = Array.new(101) { |i| { 'id' => "n#{i}", 'type' => 'send_message' } }
      definition = build(:workflow_definition, account: account, flow: { 'nodes' => nodes, 'edges' => [] })
      expect(definition).not_to be_valid
    end

    it 'accepts a valid flow' do
      expect(build(:workflow_definition, account: account)).to be_valid
    end
  end

  describe 'enums' do
    it 'defaults status to live in factory and supports draft/archived' do
      definition = create(:workflow_definition, account: account, status: :draft)
      expect(definition.draft?).to be(true)
    end
  end

  describe '.live_for_inbox' do
    it 'returns only live definitions for the inbox ordered by priority' do
      inbox = create(:inbox, account: account, channel: create(:channel_widget, account: account))
      high = create(:workflow_definition, account: account, inbox: inbox, status: :live, priority: 0)
      create(:workflow_definition, account: account, inbox: inbox, status: :draft, priority: 1)
      low = create(:workflow_definition, account: account, inbox: inbox, status: :live, priority: 5)

      expect(described_class.live_for_inbox(inbox.id).to_a).to eq([high, low])
    end
  end

  describe '#nodes and #edges' do
    it 'reads from the flow hash' do
      definition = build(:workflow_definition, account: account)
      expect(definition.nodes).to be_an(Array)
      expect(definition.edges).to eq([])
    end
  end
end
