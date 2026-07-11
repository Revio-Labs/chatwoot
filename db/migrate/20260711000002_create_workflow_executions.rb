class CreateWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_executions do |t|
      t.references :account, null: false, index: true
      t.references :conversation, null: false
      t.references :workflow_definition, index: true
      t.string :current_node_id
      t.integer :status, default: 0, null: false
      t.jsonb :flow_snapshot, default: {}, null: false
      t.jsonb :variables, default: {}
      t.jsonb :steps, default: []
      t.datetime :wake_at
      t.datetime :completed_at
      t.datetime :last_activity_at

      t.timestamps
    end
    add_index :workflow_executions, :conversation_id, unique: true,
                                                      where: 'status = 0', name: 'idx_workflow_exec_one_active_per_conversation'
    add_index :workflow_executions, [:account_id, :workflow_definition_id, :status, :created_at],
              name: 'idx_workflow_exec_reporting'
    add_index :workflow_executions, :wake_at, where: 'status = 0 AND wake_at IS NOT NULL'
  end
end
