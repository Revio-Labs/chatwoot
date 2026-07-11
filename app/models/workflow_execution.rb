# == Schema Information
#
# Table name: workflow_executions
#
#  id                     :bigint           not null, primary key
#  completed_at           :datetime
#  flow_snapshot          :jsonb            not null
#  last_activity_at       :datetime
#  status                 :integer          default("active"), not null
#  steps                  :jsonb
#  variables              :jsonb
#  wake_at                :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  conversation_id        :bigint           not null
#  current_node_id        :string
#  workflow_definition_id :bigint
#
# Indexes
#
#  idx_workflow_exec_one_active_per_conversation        (conversation_id) UNIQUE WHERE (status = 0)
#  idx_workflow_exec_reporting                          (account_id,workflow_definition_id,status,created_at)
#  index_workflow_executions_on_account_id              (account_id)
#  index_workflow_executions_on_conversation_id         (conversation_id)
#  index_workflow_executions_on_wake_at                 (wake_at) WHERE ((status = 0) AND (wake_at IS NOT NULL))
#  index_workflow_executions_on_workflow_definition_id  (workflow_definition_id)
#
class WorkflowExecution < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :workflow_definition, optional: true

  enum status: { active: 0, completed: 1, interrupted: 2, handed_off: 3 }

  validates :variables, jsonb_attributes_length: true

  def nodes
    flow_snapshot['nodes'] || []
  end

  def edges
    flow_snapshot['edges'] || []
  end

  def current_node
    nodes.find { |node| node['id'] == current_node_id }
  end

  def record_step(node_id)
    self.steps = steps + [{ 'node_id' => node_id, 'entered_at' => Time.current.iso8601 }]
    self.current_node_id = node_id
    self.last_activity_at = Time.current
  end
end
