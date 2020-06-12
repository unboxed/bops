# frozen_string_literal: true

FactoryBot.define do
  factory :drawing do
    name { 'Side elevation' }
    planning_application
  end

  trait :with_plan do
    plan { fixture_file_upload(Rails.root.join("spec/fixtures/images/existing-floorplan.png"), "existing-floorplan/png") }
  end
end
