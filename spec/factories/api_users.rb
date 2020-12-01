# frozen_string_literal: true

FactoryBot.define do
  factory :api_user do
    name { Faker::Name.name }
    token { "dsafdsaf87897dsf8" }
  end
end
