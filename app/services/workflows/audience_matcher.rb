# Decides whether a workflow definition's trigger_rules (audience) match a given
# conversation/contact — the mechanism that lets one inbox serve multiple regions
# and user types (AU/SG, Hosts/Visitors) by attribute, like Intercom.
#
# trigger_rules shape:
#   { "contact_type" => "any" | "identified" | "visitor",
#     "conditions" => [ { attribute_key, scope, filter_operator, values } ] }
class Workflows::AudienceMatcher
  include Workflows::ConditionEvaluator

  attr_reader :conversation

  def initialize(conversation:)
    @conversation = conversation
  end

  def matches?(definition)
    rules = definition.trigger_rules || {}
    return true if rules.blank?

    contact_type_matches?(rules['contact_type']) && conditions_met?(rules['conditions'])
  end

  private

  def contact_type_matches?(contact_type)
    return true if contact_type.blank? || contact_type == 'any'

    contact_type == 'identified' ? identified_contact? : !identified_contact?
  end

  def identified_contact?
    contact = conversation.contact
    contact&.identifier.present? || contact&.email.present?
  end
end
