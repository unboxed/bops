# frozen_string_literal: true

FactoryBot.define do
  factory :drawing do
    planning_application
  end

  trait :with_plan do
    plan { fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png") }
  end

  trait :archived do
    archived_at { Time.current }
  end

  trait :proposed_tags do
    tags { [Drawing::PROPOSED_TAGS.first] }
  end

  trait :existing_tags do
    tags { [Drawing::EXISTING_TAGS.first] }
  end

  trait :numbered do
    numbers { "drawing_number" }
  end
end
