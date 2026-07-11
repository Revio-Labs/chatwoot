class CreateTicketTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_types do |t|
      t.references :account, null: false, index: true
      t.string :name, null: false
      t.integer :category, default: 0, null: false
      t.string :icon, default: ''
      t.jsonb :field_schema, default: []
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :ticket_types, [:account_id, :name], unique: true
  end
end
