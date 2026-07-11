# Evaluates workflow edge conditions against contact/conversation attributes.
# Condition shape mirrors automation rules: { attribute_key, filter_operator, values, scope }.
module Workflows::ConditionEvaluator
  def conditions_met?(conditions)
    Array(conditions).all? do |condition|
      actual = attribute_value(condition)
      expected = Array(condition['values']).map(&:to_s)
      case condition['filter_operator']
      when 'not_equal_to' then expected.exclude?(actual.to_s)
      when 'contains' then expected.any? { |value| actual.to_s.downcase.include?(value.downcase) }
      else expected.include?(actual.to_s)
      end
    end
  end

  def attribute_value(condition)
    key = condition['attribute_key']
    target = condition['scope'] == 'conversation' ? conversation : conversation.contact
    target.custom_attributes&.[](key) || target.try(key)
  end
end
