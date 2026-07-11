# == Schema Information
#
# Table name: ticket_types
#
#  id           :bigint           not null, primary key
#  category     :integer          default("customer"), not null
#  field_schema :jsonb
#  icon         :string           default("")
#  name         :string           not null
#  status       :integer          default("active"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#
# Indexes
#
#  index_ticket_types_on_account_id           (account_id)
#  index_ticket_types_on_account_id_and_name  (account_id,name) UNIQUE
#
class TicketType < ApplicationRecord
  MAX_FIELDS = 50

  belongs_to :account
  has_many :tickets, dependent: :restrict_with_error

  enum category: { customer: 0, back_office: 1, tracker: 2 }
  enum status: { active: 0, archived: 1 }

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :field_schema_is_valid

  private

  def field_schema_is_valid
    return if field_schema.blank?

    errors.add(:field_schema, 'must be an array') and return unless field_schema.is_a?(Array)

    errors.add(:field_schema, "exceeds #{MAX_FIELDS} fields") if field_schema.length > MAX_FIELDS
  end
end
