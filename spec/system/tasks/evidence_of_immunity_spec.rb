# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Evidence of immunity task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assess-immunity/evidence-of-immunity") }

  let(:planning_application) do
    create(:planning_application, :ldc_existing, :in_assessment, :with_immunity, local_authority:)
  end

  let!(:utility_bill_group) do
    create(
      :evidence_group,
      :with_document,
      start_date: "2016-02-02",
      end_date: "2020-02-02",
      tag: "utilityBill",
      immunity_detail: planning_application.immunity_detail
    )
  end

  let!(:building_control_group) do
    create(
      :evidence_group,
      :with_document,
      tag: "buildingControlCertificate",
      start_date: "2012-02-10",
      end_date: nil,
      immunity_detail: planning_application.immunity_detail
    )
  end

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "shows the task in the sidebar" do
    within :sidebar do
      expect(page).to have_link("Evidence of immunity")
    end
  end

  it "shows immunity details and evidence groups" do
    within :sidebar do
      click_link "Evidence of immunity"
    end

    expect(page).to have_content("Evidence of immunity")
    expect(page).to have_content("Utility bills (1)")
    expect(page).to have_content("Building control certificates (1)")
  end

  it "saves a draft with edited dates", :capybara do
    within :sidebar do
      click_link "Evidence of immunity"
    end

    click_button "Utility bills (1)"

    within(:open_accordion) do
      within_fieldset("Runs until") do
        fill_in "Day", with: "03"
        fill_in "Month", with: "12"
        fill_in "Year", with: "2021"
      end

      fill_in "Add comment", with: "This is my comment"
    end

    click_button "Save changes"

    expect(page).to have_content("Evidence of immunity successfully updated")
    expect(task.reload).to be_in_progress

    review = Review.evidence.last
    expect(review).to have_attributes(
      status: "in_progress",
      specific_attributes: hash_including("review_type" => "evidence")
    )
  end

  it "saves and completes with missing evidence marked", :capybara do
    within :sidebar do
      click_link "Evidence of immunity"
    end

    click_button "Utility bills (1)"

    within(:open_accordion) do
      check "Missing evidence (gap in time)"
      fill_in "List all the gap(s) in time", with: "May 2019"
      fill_in "Add comment", with: "Not good enough"
    end

    click_button "Utility bills (1)"

    click_button "Building control certificates (1)"

    within(:open_accordion) do
      fill_in "Add comment", with: "This proves it"
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Evidence of immunity successfully updated")
    expect(task.reload).to be_completed

    review = Review.evidence.last
    expect(review).to have_attributes(
      status: "complete",
      specific_attributes: hash_including("review_type" => "evidence")
    )

    utility_bill_group.reload
    expect(utility_bill_group.missing_evidence).to be true
    expect(utility_bill_group.missing_evidence_entry).to eq("May 2019")
  end

  it "can save draft then complete", :capybara do
    within :sidebar do
      click_link "Evidence of immunity"
    end

    click_button "Utility bills (1)"

    within(:open_accordion) do
      within_fieldset("Runs until") do
        fill_in "Day", with: "03"
        fill_in "Month", with: "12"
        fill_in "Year", with: "2021"
      end

      fill_in "Add comment", with: "Comment on utility bills"
    end

    click_button "Save changes"

    expect(page).to have_content("Evidence of immunity successfully updated")
    expect(task.reload).to be_in_progress

    within :sidebar do
      click_link "Evidence of immunity"
    end

    click_button "Utility bills (1)"

    within(:open_accordion) do
      within_fieldset("Runs until") do
        expect(page).to have_field("Day", with: "3")
        expect(page).to have_field("Month", with: "12")
        expect(page).to have_field("Year", with: "2021")
      end
    end

    click_button "Save and mark as complete"

    expect(page).to have_content("Evidence of immunity successfully updated")
    expect(task.reload).to be_completed
  end
end
