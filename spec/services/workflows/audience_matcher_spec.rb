require 'rails_helper'

RSpec.describe Workflows::AudienceMatcher do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }

  def definition(trigger_rules)
    build(:workflow_definition, account: account, inbox: inbox, trigger_rules: trigger_rules)
  end

  def conversation_for(contact)
    create(:conversation, account: account, inbox: inbox, contact: contact)
  end

  it 'matches everyone when trigger_rules are blank' do
    contact = create(:contact, account: account)
    matcher = described_class.new(conversation: conversation_for(contact))
    expect(matcher.matches?(definition({}))).to be(true)
  end

  it 'matches on a contact custom attribute' do
    contact = create(:contact, account: account, custom_attributes: { 'market' => 'Australia' })
    matcher = described_class.new(conversation: conversation_for(contact))
    rules = { 'conditions' => [{ 'attribute_key' => 'market', 'scope' => 'contact',
                                 'filter_operator' => 'equal_to', 'values' => ['Australia'] }] }
    expect(matcher.matches?(definition(rules))).to be(true)

    sg_rules = { 'conditions' => [{ 'attribute_key' => 'market', 'scope' => 'contact',
                                    'filter_operator' => 'equal_to', 'values' => ['Singapore'] }] }
    expect(matcher.matches?(definition(sg_rules))).to be(false)
  end

  it 'matches identified vs visitor contact_type' do
    identified = create(:contact, account: account, identifier: 'user_1')
    anonymous = create(:contact, account: account, identifier: nil, email: nil)

    identified_rules = { 'contact_type' => 'identified' }
    visitor_rules = { 'contact_type' => 'visitor' }

    expect(described_class.new(conversation: conversation_for(identified)).matches?(definition(identified_rules))).to be(true)
    expect(described_class.new(conversation: conversation_for(anonymous)).matches?(definition(identified_rules))).to be(false)
    expect(described_class.new(conversation: conversation_for(anonymous)).matches?(definition(visitor_rules))).to be(true)
  end

  it 'requires both contact_type and conditions to match' do
    contact = create(:contact, account: account, identifier: 'u1', custom_attributes: { 'market' => 'Australia' })
    matcher = described_class.new(conversation: conversation_for(contact))
    rules = {
      'contact_type' => 'identified',
      'conditions' => [{ 'attribute_key' => 'market', 'scope' => 'contact',
                         'filter_operator' => 'equal_to', 'values' => ['Singapore'] }]
    }
    expect(matcher.matches?(definition(rules))).to be(false)
  end
end
