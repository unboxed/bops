# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    planning_application
    file do
      fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png")
    end
  end

  trait :with_file do
    file do
      fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png")
    end
  end

  trait :with_other_file do
    file do
      fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-first-floor-plan.pdf"),
        "proposed-first-floor-plan/pdf")
    end
  end

  trait :archived do
    archived_at { Time.zone.now }
  end

  trait :with_tags do
    tags { %w[elevations.proposed photographs.proposed] }
  end

  trait :referenced do
    numbers { "document_number" }
    referenced_in_decision_notice { true }
  end

  trait :public do
    publishable { true }
  end

  trait :consultees do
    available_to_consultees { true }
  end

  trait :evidence do
    tags { ["photographs.proposed", "utilityBill"] }
  end

  trait :floorplan_tags do
    tags { ["roofPlan.existing", "roofPlan.proposed"] }
  end
end
