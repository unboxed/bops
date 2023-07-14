# frozen_string_literal: true

FactoryBot.define do
  factory :condition_reason do
    text { "To comply with the requirements of Section 91" }
    local_authority do
      LocalAuthority.find_by(subdomain: "buckinghamshire") || create(:local_authority)
    end
    condition
  end
end
