# frozen_string_literal: true

FactoryBot.define do
  factory :decision do
    planning_application
    user
  end

  trait :granted do
    status { :granted }
  end

  trait :refused do
    status { :refused }
  end

  trait :refused_with_comment do
    status { :refused }
    comment_unmet { "This has been refused." }
  end
end
