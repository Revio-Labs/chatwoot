# == Schema Information
#
# Table name: tickets
#
#  id                :bigint           not null, primary key
#  custom_attributes :jsonb
#  description       :text
#  resolved_at       :datetime
#  state             :integer          default("submitted"), not null
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  assignee_id       :bigint
#  contact_id        :bigint
#  conversation_id   :bigint
#  display_id        :integer          not null
#  team_id           :bigint
#  ticket_type_id    :bigint           not null
#
# Indexes
#
#  index_tickets_on_account_id                               (account_id)
#  index_tickets_on_account_id_and_display_id                (account_id,display_id) UNIQUE
#  index_tickets_on_account_id_and_ticket_type_id_and_state  (account_id,ticket_type_id,state)
#  index_tickets_on_assignee_id                              (assignee_id)
#  index_tickets_on_contact_id                               (contact_id)
#  index_tickets_on_conversation_id                          (conversation_id)
#  index_tickets_on_team_id                                  (team_id)
#  index_tickets_on_ticket_type_id                           (ticket_type_id)
#
class Ticket < ApplicationRecord
  belongs_to :account
  belongs_to :ticket_type
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :team, optional: true
  has_many :ticket_links, dependent: :destroy_async

  enum state: { submitted: 0, in_progress: 1, waiting: 2, resolved: 3 }

  validates :title, presence: true
  validates :custom_attributes, jsonb_attributes_length: true

  after_create_commit :load_attributes_created_by_db_triggers
  before_save :set_resolved_at, if: :will_save_change_to_state?

  # Per-account sequential display_id set via a DB trigger; fetch it after insert.
  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('tick_dpid_seq_' || NEW.account_id);"
  end

  private

  def load_attributes_created_by_db_triggers
    obj_from_db = self.class.find(id)
    self[:display_id] = obj_from_db[:display_id]
  end

  def set_resolved_at
    self.resolved_at = resolved? ? Time.current : nil
  end
end
