class CreateWorkflowDefinitions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_definitions do |t|
      t.references :account, null: false, index: true
      t.references :inbox, null: false, index: true
      t.string :name, null: false
      t.integer :status, default: 0, null: false
      t.integer :trigger_type, default: 0, null: false
      t.integer :priority, default: 0, null: false
      t.integer :audience_type, default: 0, null: false
      t.jsonb :flow, default: {}, null: false
      t.jsonb :trigger_rules, default: {}

      t.timestamps
    end
    add_index :workflow_definitions, [:account_id, :inbox_id, :status, :priority],
              name: 'idx_workflow_defs_on_inbox_status_priority'
  end
end
