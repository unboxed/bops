# frozen_string_literal: true

FactoryBot.define do
  factory :case_record do
    local_authority { create(:local_authority) }
  end
end
