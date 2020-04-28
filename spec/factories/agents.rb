FactoryBot.define do
  factory :agent do
    name { Faker::Name.name }
    phone { "0719 111111" }
    email { Faker::Internet.email }
  end
end
