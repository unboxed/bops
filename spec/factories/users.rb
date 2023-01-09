# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    local_authority do
      LocalAuthority.find_by(subdomain: "buckinghamshire") || create(:local_authority)
    end
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password { "Id!l]GT1-{ncnZ!oSvrF.*jx\\w1>V@]_}e>B,A\\yI&'4z6P$2iIQDZ-*rsiFoBP~0=uL/%2wHFg_RrF%nx[`oeY4" }
    mobile_number { "07656546552" }
  end

  trait :assessor do
    role { :assessor }
  end

  trait :reviewer do
    role { :reviewer }
  end

  trait :administrator do
    role { :administrator }
  end
end
