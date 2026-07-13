require 'rails_helper'

RSpec.describe WorkflowExecution do
  let(:account) { create(:account) }

  describe 'enums' do
    it 'supports active/completed/interrupted/handed_off' do
      execution = create(:workflow_execution, account: account)
      expect(execution.active?).to be(true)
      execution.handed_off!
      expect(execution.handed_off?).to be(true)
    end
  end

  describe '#record_step' do
    it 'appends to steps, sets current_node_id and last_activity_at' do
      execution = create(:workflow_execution, account: account)
      execution.record_step('welcome')
      expect(execution.current_node_id).to eq('welcome')
      expect(execution.steps.last['node_id']).to eq('welcome')
      expect(execution.last_activity_at).to be_present
    end
  end

  describe '#current_node' do
    it 'finds the node in the snapshot by current_node_id' do
      execution = create(:workflow_execution, account: account, current_node_id: 'welcome')
      expect(execution.current_node['type']).to eq('send_message')
    end
  end

  describe 'one active execution per conversation' do
    it 'is enforced by the partial unique index' do
      conversation = create(:conversation, account: account)
      create(:workflow_execution, account: account, conversation: conversation, status: :active)
      dup = build(:workflow_execution, account: account, conversation: conversation, status: :active)
      expect { dup.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
