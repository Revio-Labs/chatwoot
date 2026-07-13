require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::TicketsController', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:ticket_type) { create(:ticket_type, account: account) }

  before { account.update!(tickets_enabled: true) }

  describe 'GET index' do
    it 'returns unauthorized for anonymous users' do
      get "/api/v1/accounts/#{account.id}/tickets"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists tickets and filters by state' do
      create(:ticket, account: account, ticket_type: ticket_type, state: :submitted)
      create(:ticket, account: account, ticket_type: ticket_type, state: :resolved)
      get "/api/v1/accounts/#{account.id}/tickets", params: { state: 'resolved' },
                                                    headers: administrator.create_new_auth_token
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].length).to eq(1)
    end

    it 'is forbidden when tickets are disabled' do
      account.update!(tickets_enabled: false)
      get "/api/v1/accounts/#{account.id}/tickets", headers: administrator.create_new_auth_token
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create' do
    it 'creates a ticket' do
      params = { ticket_type_id: ticket_type.id, title: 'Scratch', state: 'submitted' }
      expect do
        post "/api/v1/accounts/#{account.id}/tickets", params: params,
                                                       headers: administrator.create_new_auth_token, as: :json
      end.to change(Ticket, :count).by(1)
      expect(response).to have_http_status(:success)
    end
  end
end
