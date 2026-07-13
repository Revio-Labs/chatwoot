require 'rails_helper'

RSpec.describe Workflows::TriggerService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let(:conversation) do
    create(:conversation, account: account, inbox: inbox, status: :pending)
  end

  before { account.update!(workflows_enabled: true) }

  it 'does nothing when the workflows feature is off' do
    account.update!(workflows_enabled: false)
    create(:workflow_definition, account: account, inbox: inbox, status: :live)
    expect(described_class.new(conversation: conversation).perform).to be_nil
    expect(conversation.workflow_executions).to be_empty
  end

  it 'starts the top-priority live definition and snapshots its flow' do
    create(:workflow_definition, account: account, inbox: inbox, status: :live, priority: 5,
                                 flow: { 'nodes' => [{ 'id' => 'low', 'type' => 'send_message', 'content' => 'low' }], 'edges' => [] })
    top = create(:workflow_definition, account: account, inbox: inbox, status: :live, priority: 0,
                                       flow: { 'nodes' => [{ 'id' => 'top', 'type' => 'send_message', 'content' => 'top' }], 'edges' => [] })

    execution = described_class.new(conversation: conversation).perform
    expect(execution.workflow_definition).to eq(top)
    expect(execution.flow_snapshot['nodes'].first['id']).to eq('top')
  end

  it 'interrupts any prior active execution before starting a new one' do
    definition = create(:workflow_definition, account: account, inbox: inbox, status: :live)
    prior = create(:workflow_execution, account: account, conversation: conversation,
                                        workflow_definition: definition, status: :active)
    described_class.new(conversation: conversation).perform
    expect(prior.reload).to be_interrupted
  end

  it 'ignores definitions whose trigger_type does not match' do
    create(:workflow_definition, account: account, inbox: inbox, status: :live, trigger_type: :manual)
    expect(described_class.new(conversation: conversation, trigger_type: :conversation_created).perform).to be_nil
  end

  describe 'audience matching (one inbox, AU + SG)' do
    def region_workflow(name, market)
      create(:workflow_definition, account: account, inbox: inbox, status: :live, name: name,
                                   trigger_rules: { 'conditions' => [
                                     { 'attribute_key' => 'market', 'scope' => 'contact',
                                       'filter_operator' => 'equal_to', 'values' => [market] }
                                   ] })
    end

    before do
      region_workflow('AU Hosts', 'Australia')
      region_workflow('SG Hosts', 'Singapore')
    end

    it 'fires the AU workflow for an AU contact' do
      conversation.contact.update!(custom_attributes: { 'market' => 'Australia' })
      execution = described_class.new(conversation: conversation).perform
      expect(execution.workflow_definition.name).to eq('AU Hosts')
    end

    it 'fires the SG workflow for a SG contact' do
      conversation.contact.update!(custom_attributes: { 'market' => 'Singapore' })
      execution = described_class.new(conversation: conversation).perform
      expect(execution.workflow_definition.name).to eq('SG Hosts')
    end

    it 'starts nothing when no audience matches' do
      conversation.contact.update!(custom_attributes: { 'market' => 'Malaysia' })
      expect(described_class.new(conversation: conversation).perform).to be_nil
    end
  end
end
