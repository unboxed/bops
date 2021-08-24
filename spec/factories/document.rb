# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    planning_application
    file { fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png") }
  end

  trait :with_file do
    file { fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png") }
  end

  trait :archived do
    archived_at { Time.zone.now }
  end

  trait :with_tags do
    tags { %w[Side Elevation Proposed Photograph] }
  end

  trait :referenced do
    numbers { "document_number" }
    referenced_in_decision_notice { true }
  end

  trait :public do
    publishable { true }
  end
end
