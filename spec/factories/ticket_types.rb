# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_type do
    account
    sequence(:name) { |n| "Ticket Type #{n}" }
    category { :customer }
    status { :active }
    field_schema { [] }
  end
end
