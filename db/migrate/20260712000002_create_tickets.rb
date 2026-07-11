class CreateTickets < ActiveRecord::Migration[7.1]
  def up
    create_tickets_table
    create_display_id_triggers
    backfill_existing_account_sequences
  end

  def down
    drop_trigger('tickets_before_insert_row_tr', 'tickets', generated: true)
    drop_trigger('tick_dpid_before_insert', 'accounts', generated: true)
    drop_table :tickets
  end

  private

  def create_tickets_table
    create_table :tickets do |t|
      t.references :account, null: false, index: true
      t.references :ticket_type, null: false, index: true
      t.references :conversation, index: true
      t.references :contact, index: true
      t.references :assignee, index: true
      t.references :team, index: true
      t.integer :display_id, null: false
      t.string :title, null: false
      t.text :description
      t.integer :state, default: 0, null: false
      t.jsonb :custom_attributes, default: {}
      t.datetime :resolved_at

      t.timestamps
    end
    add_index :tickets, [:account_id, :display_id], unique: true
    add_index :tickets, [:account_id, :ticket_type_id, :state]
  end

  # Per-account display_id sequence, mirroring conversations/campaigns (hairtrigger).
  # The trigger DSL also lives in the Account and Ticket models so schema.rb + schema:load stay correct.
  def create_display_id_triggers
    create_trigger('tick_dpid_before_insert', generated: true, compatibility: 1)
      .on('accounts').name('tick_dpid_before_insert').after(:insert).for_each(:row) do
      "execute format('create sequence IF NOT EXISTS tick_dpid_seq_%s', NEW.id);"
    end

    create_trigger('tickets_before_insert_row_tr', generated: true, compatibility: 1)
      .on('tickets').before(:insert).for_each(:row) do
      "NEW.display_id := nextval('tick_dpid_seq_' || NEW.account_id);"
    end
  end

  def backfill_existing_account_sequences
    execute(<<~SQL.squish)
      DO $$
      DECLARE acct RECORD;
      BEGIN
        FOR acct IN SELECT id FROM accounts LOOP
          EXECUTE format('create sequence IF NOT EXISTS tick_dpid_seq_%s', acct.id);
        END LOOP;
      END $$;
    SQL
  end
end
