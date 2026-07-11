class CreateTicketLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_links do |t|
      t.references :account, null: false, index: true
      t.references :ticket, null: false, index: true
      t.references :conversation, null: false, index: true

      t.timestamps
    end
    add_index :ticket_links, [:ticket_id, :conversation_id], unique: true
  end
end
