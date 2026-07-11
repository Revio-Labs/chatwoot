# == Schema Information
#
# Table name: ticket_links
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  ticket_id       :bigint           not null
#
# Indexes
#
#  index_ticket_links_on_account_id                     (account_id)
#  index_ticket_links_on_conversation_id                (conversation_id)
#  index_ticket_links_on_ticket_id                      (ticket_id)
#  index_ticket_links_on_ticket_id_and_conversation_id  (ticket_id,conversation_id) UNIQUE
#
class TicketLink < ApplicationRecord
  belongs_to :account
  belongs_to :ticket
  belongs_to :conversation

  validates :ticket_id, uniqueness: { scope: :conversation_id }
end
