# frozen_string_literal: true

FactoryBot.define do
  factory :drawing do
    planning_application
  end

  trait :with_plan do
    plan { fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png") }
  end
end
