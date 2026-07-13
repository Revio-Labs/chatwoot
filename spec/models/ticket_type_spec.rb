require 'rails_helper'

RSpec.describe TicketType do
  let(:account) { create(:account) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    it 'enforces name uniqueness per account' do
      create(:ticket_type, account: account, name: 'Damage')
      dup = build(:ticket_type, account: account, name: 'Damage')
      expect(dup).not_to be_valid
    end

    it 'allows the same name across different accounts' do
      create(:ticket_type, account: account, name: 'Damage')
      other = build(:ticket_type, account: create(:account), name: 'Damage')
      expect(other).to be_valid
    end

    it 'rejects a non-array field_schema' do
      type = build(:ticket_type, account: account, field_schema: { 'x' => 1 })
      expect(type).not_to be_valid
    end

    it 'rejects more than the max number of fields' do
      fields = Array.new(TicketType::MAX_FIELDS + 1) { |i| { 'name' => "f#{i}" } }
      type = build(:ticket_type, account: account, field_schema: fields)
      expect(type).not_to be_valid
    end
  end

  describe 'enums' do
    it 'supports customer/back_office/tracker categories' do
      type = create(:ticket_type, account: account, category: :back_office)
      expect(type.back_office?).to be(true)
    end
  end
end
