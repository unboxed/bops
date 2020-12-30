# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    planning_application
  end

  trait :with_plan do
    plan { fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png") }
  end

  trait :archived do
    archived_at { Time.current }
  end

  trait :proposed_tags do
    tags { [Document::PROPOSED_TAGS.first] }
  end

  trait :existing_tags do
    tags { [Document::EXISTING_TAGS.first] }
  end

  trait :numbered do
    numbers { "document_number" }
  end
end
