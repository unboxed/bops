# frozen_string_literal: true

FactoryBot.define do
  factory :decision do
    planning_application
    user
  end

  trait :granted do
    status { :granted }

    after(:create) do |decision|
      decision.determined_at = Time.current if decision.user.reviewer?
      decision.save!
    end
  end

  trait :granted_with_comment do
    status { :granted }
    comment_met { "This has been granted." }

    after(:create) do |decision|
      decision.determined_at = Time.current if decision.user.reviewer?
      decision.save!
    end
  end

  trait :refused do
    status { :refused }

    after(:create) do |decision|
      decision.determined_at = Time.current if decision.user.reviewer?
      decision.save!
    end
  end

  trait :refused_with_comment do
    status { :refused }
    comment_unmet { "This has been refused." }

    after(:create) do |decision|
      decision.determined_at = Time.current if decision.user.reviewer?
      decision.save!
    end
  end
end
