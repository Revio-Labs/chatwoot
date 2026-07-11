# == Schema Information
#
# Table name: workflow_definitions
#
#  id            :bigint           not null, primary key
#  audience_type :integer          default("customer_facing"), not null
#  flow          :jsonb            not null
#  name          :string           not null
#  priority      :integer          default(0), not null
#  status        :integer          default("draft"), not null
#  trigger_rules :jsonb
#  trigger_type  :integer          default("conversation_created"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  inbox_id      :bigint           not null
#
# Indexes
#
#  idx_workflow_defs_on_inbox_status_priority  (account_id,inbox_id,status,priority)
#  index_workflow_definitions_on_account_id    (account_id)
#  index_workflow_definitions_on_inbox_id      (inbox_id)
#
class WorkflowDefinition < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  has_many :workflow_executions, dependent: :nullify

  enum status: { draft: 0, live: 1, archived: 2 }
  enum trigger_type: { conversation_created: 0, first_message: 1, inactivity: 2, manual: 3 }
  enum audience_type: { customer_facing: 0, background: 1 }

  validates :name, presence: true
  validates :flow, workflow_flow: true

  scope :live_for_inbox, ->(inbox_id) { live.where(inbox_id: inbox_id).order(:priority) }

  def nodes
    flow['nodes'] || []
  end

  def edges
    flow['edges'] || []
  end
end
