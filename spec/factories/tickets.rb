# frozen_string_literal: true

FactoryBot.define do
  factory :ticket do
    account
    ticket_type { association :ticket_type, account: account }
    title { 'Bumper scratch' }
    state { :submitted }
    custom_attributes { {} }
  end
end
