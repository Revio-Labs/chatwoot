require 'rails_helper'

RSpec.describe Workflows::ConditionEvaluator do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, custom_attributes: { 'market' => 'Australia' }) }
  let(:conversation) { create(:conversation, account: account, contact: contact) }

  let(:evaluator) do
    conv = conversation
    Class.new do
      include Workflows::ConditionEvaluator
      define_method(:conversation) { conv }
    end.new
  end

  def condition(operator, values, scope: 'contact', key: 'market')
    [{ 'attribute_key' => key, 'scope' => scope, 'filter_operator' => operator, 'values' => values }]
  end

  it 'matches equal_to' do
    expect(evaluator.conditions_met?(condition('equal_to', ['Australia']))).to be(true)
    expect(evaluator.conditions_met?(condition('equal_to', ['Singapore']))).to be(false)
  end

  it 'matches not_equal_to' do
    expect(evaluator.conditions_met?(condition('not_equal_to', ['Singapore']))).to be(true)
    expect(evaluator.conditions_met?(condition('not_equal_to', ['Australia']))).to be(false)
  end

  it 'matches contains case-insensitively' do
    expect(evaluator.conditions_met?(condition('contains', ['austral']))).to be(true)
  end

  it 'requires all conditions to pass' do
    conditions = condition('equal_to', ['Australia']) + condition('equal_to', ['Singapore'])
    expect(evaluator.conditions_met?(conditions)).to be(false)
  end
end
