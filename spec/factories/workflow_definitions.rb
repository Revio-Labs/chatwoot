# frozen_string_literal: true

FactoryBot.define do
  factory :workflow_definition do
    account
    sequence(:name) { |n| "Workflow #{n}" }
    status { :live }
    trigger_type { :conversation_created }
    audience_type { :customer_facing }
    priority { 0 }
    flow do
      {
        'nodes' => [
          { 'id' => 'welcome', 'type' => 'send_message', 'content' => 'Hi there' }
        ],
        'edges' => []
      }
    end

    after(:build) do |definition|
      definition.inbox ||= create(
        :inbox,
        account: definition.account,
        channel: create(:channel_widget, account: definition.account)
      )
    end
  end
end
