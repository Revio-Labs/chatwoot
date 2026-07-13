# frozen_string_literal: true

FactoryBot.define do
  factory :ticket_link do
    account
    ticket { association :ticket, account: account }
    conversation { association :conversation, account: account }
  end
end
