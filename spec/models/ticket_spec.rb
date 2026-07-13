require 'rails_helper'

RSpec.describe Ticket do
  let(:account) { create(:account) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'display_id' do
    it 'is assigned a per-account sequential number by the db trigger' do
      first = create(:ticket, account: account)
      second = create(:ticket, account: account)
      expect(second.display_id).to eq(first.display_id + 1)
    end

    it 'sequences independently per account' do
      create(:ticket, account: account)
      other_account = create(:account)
      other_ticket = create(:ticket, account: other_account)
      expect(other_ticket.display_id).to eq(1)
    end
  end

  describe 'state transitions' do
    it 'sets resolved_at when moving to resolved and clears it otherwise' do
      ticket = create(:ticket, account: account, state: :submitted)
      expect(ticket.resolved_at).to be_nil

      ticket.update!(state: :resolved)
      expect(ticket.resolved_at).to be_present

      ticket.update!(state: :in_progress)
      expect(ticket.resolved_at).to be_nil
    end
  end
end
