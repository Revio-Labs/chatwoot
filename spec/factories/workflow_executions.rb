# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_execution do
    account
    conversation { association :conversation, account: account }
    workflow_definition { association :workflow_definition, account: account }
    status { :active }
    flow_snapshot do
      {
        'nodes' => [
          { 'id' => 'welcome', 'type' => 'send_message', 'content' => 'Hi there' }
        ],
        'edges' => []
      }
    end
    variables { {} }
    steps { [] }
  end
end
