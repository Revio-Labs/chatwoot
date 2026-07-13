require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::WorkflowsController', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }

  before { account.update!(workflows_enabled: true) }

  describe 'GET /api/v1/accounts/{account}/workflows' do
    it 'returns unauthorized for anonymous users' do
      get "/api/v1/accounts/#{account.id}/workflows"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'forbids non-administrators' do
      create(:workflow_definition, account: account, inbox: inbox)
      get "/api/v1/accounts/#{account.id}/workflows", headers: agent.create_new_auth_token
      expect(response).to have_http_status(:unauthorized)
    end

    it 'lists workflows for an administrator' do
      create(:workflow_definition, account: account, inbox: inbox)
      get "/api/v1/accounts/#{account.id}/workflows", headers: administrator.create_new_auth_token
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload'].length).to eq(1)
    end

    it 'is forbidden when the feature is disabled' do
      account.update!(workflows_enabled: false)
      get "/api/v1/accounts/#{account.id}/workflows", headers: administrator.create_new_auth_token
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/accounts/{account}/workflows' do
    it 'creates a workflow with a flow' do
      params = { name: 'AU Hosts', inbox_id: inbox.id, trigger_type: 'conversation_created',
                 status: 'draft', flow: { nodes: [{ id: 'a', type: 'send_message', content: 'hi' }], edges: [] } }
      expect do
        post "/api/v1/accounts/#{account.id}/workflows", params: params,
                                                         headers: administrator.create_new_auth_token, as: :json
      end.to change(WorkflowDefinition, :count).by(1)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH reorder' do
    it 'updates priorities from the provided order' do
      a = create(:workflow_definition, account: account, inbox: inbox, priority: 0)
      b = create(:workflow_definition, account: account, inbox: inbox, priority: 1)
      patch "/api/v1/accounts/#{account.id}/workflows/reorder",
            params: { priority_order: [b.id, a.id] },
            headers: administrator.create_new_auth_token, as: :json
      expect(response).to have_http_status(:success)
      expect(b.reload.priority).to eq(0)
      expect(a.reload.priority).to eq(1)
    end
  end

  describe 'DELETE /api/v1/accounts/{account}/workflows/{id}' do
    it 'deletes a workflow' do
      workflow = create(:workflow_definition, account: account, inbox: inbox)
      expect do
        delete "/api/v1/accounts/#{account.id}/workflows/#{workflow.id}",
               headers: administrator.create_new_auth_token
      end.to change(WorkflowDefinition, :count).by(-1)
    end
  end
end
