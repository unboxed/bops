# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assess immunity task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assess-immunity/assess-immunity") }

  let(:planning_application) do
    create(:planning_application, :ldc_existing, :in_assessment, local_authority:)
  end

  let!(:immunity_detail) do
    create(:immunity_detail, planning_application:)
  end

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "shows the task in the sidebar" do
    within :sidebar do
      expect(page).to have_link("Assess immunity")
    end
  end

  it "shows the immunity decision form" do
    within :sidebar do
      click_link "Assess immunity"
    end

    expect(page).to have_content("On the balance of probabilities, is the development immune from enforcement action?")
  end

  it "shows a validation error when no decision is selected" do
    within :sidebar do
      click_link "Assess immunity"
    end

    click_button "Save and mark as complete"

    within(".govuk-error-summary") do
      expect(page).to have_content("Select Yes or No for whether the development is immune")
    end
    expect(task.reload).to be_not_started
  end

  it "shows validation errors for Yes decision without reason or summary" do
    within :sidebar do
      click_link "Assess immunity"
    end

    choose "Yes, the development is immune"
    click_button "Save and mark as complete"

    expect(page).to have_content("Select a reason for immunity")
    expect(page).to have_content("Provide a summary of the immunity assessment")
    expect(task.reload).to be_not_started
  end

  it "shows validation errors for No decision without reason or PDR" do
    within :sidebar do
      click_link "Assess immunity"
    end

    choose "No, the development is not immune"
    click_button "Save and mark as complete"

    expect(page).to have_content("Provide a reason why the development is not immune")
    expect(page).to have_content("Select whether permitted development rights have been removed")
    expect(task.reload).to be_not_started
  end

  it "shows validation error when PDR removed but no reason given" do
    within :sidebar do
      click_link "Assess immunity"
    end

    choose "No, the development is not immune"
    fill_in "Describe why the application is not immune from enforcement", with: "Not immune because..."
    choose "Yes, permitted development rights have been removed"
    click_button "Save and mark as complete"

    expect(page).to have_content("Describe how permitted development rights have been removed")
    expect(task.reload).to be_not_started
  end

  it "saves and completes when Yes is selected with reason and summary" do
    within :sidebar do
      click_link "Assess immunity"
    end

    choose "Yes, the development is immune"
    choose "No action has been taken within 4 years for an unauthorised change of use to a single dwellinghouse"
    fill_in "Immunity from enforcement summary", with: "A summary of the immunity assessment"

    click_button "Save and mark as complete"

    expect(page).to have_content("Immunity assessment was successfully saved")
    expect(task.reload).to be_completed

    review = Review.enforcement.last
    expect(review).to have_attributes(
      owner_id: immunity_detail.id,
      assessor_id: user.id,
      status: "complete",
      specific_attributes: hash_including(
        "decision" => "Yes",
        "decision_type" => "unauthorised-change-before-2024-04-25",
        "summary" => "A summary of the immunity assessment",
        "review_type" => "enforcement"
      )
    )

    expect(PermittedDevelopmentRight.count).to eq(0)
  end

  it "saves and completes with Yes and Other reason" do
    within :sidebar do
      click_link "Assess immunity"
    end

    choose "Yes, the development is immune"
    choose "Other reason"
    fill_in "Provide the other reason why this development is immune", with: "A custom reason"
    fill_in "Immunity from enforcement summary", with: "A summary"

    click_button "Save and mark as complete"

    expect(page).to have_content("Immunity assessment was successfully saved")
    expect(task.reload).to be_completed

    review = Review.enforcement.last
    expect(review).to have_attributes(
      specific_attributes: hash_including(
        "decision" => "Yes",
        "decision_type" => "other",
        "decision_reason" => "A custom reason",
        "summary" => "A summary",
        "review_type" => "enforcement"
      )
    )
  end

  it "saves and completes with No decision and PDR removed" do
    within :sidebar do
      click_link "Assess immunity"
    end

    choose "No, the development is not immune"
    fill_in "Describe why the application is not immune from enforcement", with: "Not immune because..."
    choose "Yes, permitted development rights have been removed"
    fill_in "Describe how permitted development rights have been removed", with: "Article 4 direction"

    click_button "Save and mark as complete"

    expect(page).to have_content("Immunity assessment was successfully saved")
    expect(task.reload).to be_completed

    review = Review.enforcement.last
    expect(review).to have_attributes(
      specific_attributes: hash_including(
        "decision" => "No",
        "decision_reason" => "Not immune because...",
        "review_type" => "enforcement"
      )
    )

    pdr = PermittedDevelopmentRight.last
    expect(pdr).to have_attributes(
      removed: true,
      removed_reason: "Article 4 direction",
      status: "complete",
      assessor: user
    )
  end

  it "saves and completes with No decision and PDR not removed" do
    within :sidebar do
      click_link "Assess immunity"
    end

    choose "No, the development is not immune"
    fill_in "Describe why the application is not immune from enforcement", with: "Not immune because..."
    choose "No, permitted development rights have not been removed"

    click_button "Save and mark as complete"

    expect(page).to have_content("Immunity assessment was successfully saved")
    expect(task.reload).to be_completed

    pdr = PermittedDevelopmentRight.last
    expect(pdr).to have_attributes(
      removed: false,
      removed_reason: nil,
      status: "complete"
    )
  end

  it "saves a draft" do
    within :sidebar do
      click_link "Assess immunity"
    end

    choose "Yes, the development is immune"
    click_button "Save changes"

    expect(task.reload).to be_in_progress

    review = Review.enforcement.last
    expect(review).to have_attributes(
      status: "in_progress",
      specific_attributes: hash_including(
        "decision" => "Yes",
        "review_type" => "enforcement"
      )
    )
  end

  context "when there is an existing assessment" do
    before do
      immunity_detail.reviews.create!(
        assessor: user,
        status: "in_progress",
        review_type: "enforcement",
        decision: "Yes",
        decision_type: "other",
        decision_reason: "Previous reason",
        summary: "Previous summary"
      )
      task.start!
    end

    it "pre-populates the form with existing values" do
      within :sidebar do
        click_link "Assess immunity"
      end

      expect(page).to have_field("Yes, the development is immune", checked: true)
      expect(page).to have_field("Other reason", checked: true)
      expect(page).to have_field("Immunity from enforcement summary", with: "Previous summary")
    end
  end
end
