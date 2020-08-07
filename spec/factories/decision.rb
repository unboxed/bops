# frozen_string_literal: true

FactoryBot.define do
  factory :decision do
    planning_application
    user
    decided_at { Time.current }
  end

  trait :granted do
    status { :granted }
  end

  trait :refused do
    status { :refused }
  end

  trait :refused_with_comment do
    status { :refused }
    public_comment { "This has been refused." }
  end

  trait :refused_with_public_and_private_comment do
    status { :refused }
    public_comment { "This has been refused." }
    private_comment { "This is a private comment." }
  end
end
