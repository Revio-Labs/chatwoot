require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::TicketTypesController', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  before { account.update!(tickets_enabled: true) }

  describe 'GET index' do
    it 'lists ticket types for an administrator' do
      create(:ticket_type, account: account)
      get "/api/v1/accounts/#{account.id}/ticket_types", headers: administrator.create_new_auth_token
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].length).to eq(1)
    end
  end

  describe 'POST create' do
    it 'allows administrators to create a ticket type' do
      params = { name: 'Damage', category: 'customer', field_schema: [{ name: 'plate', type: 'text' }] }
      expect do
        post "/api/v1/accounts/#{account.id}/ticket_types", params: params,
                                                            headers: administrator.create_new_auth_token, as: :json
      end.to change(TicketType, :count).by(1)
    end

    it 'forbids agents from creating a ticket type' do
      post "/api/v1/accounts/#{account.id}/ticket_types", params: { name: 'X' },
                                                          headers: agent.create_new_auth_token, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
