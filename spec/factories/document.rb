# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    planning_application
  end

  trait :with_file do
    file { fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png") }
  end

  trait :archived do
    archived_at { Time.zone.now }
  end

  trait :with_tags do
    tags { %w[Side Elevation Proposed] }
  end

  trait :numbered do
    numbers { "document_number" }
  end
end
