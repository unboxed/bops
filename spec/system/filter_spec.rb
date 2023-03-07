# frozen_string_literal: true

require "rails_helper"

RSpec.describe "filtering planning applications" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority: local_authority) }

  let(:other_user) { create(:user, :assessor, local_authority: local_authority) }

  let!(:not_started_planning_application) do
    create(
      :planning_application,
      :not_started,
      user: user,
      local_authority: local_authority,
    )
  end

  let!(:invalid_planning_application) do
    create(
      :planning_application,
      :invalidated,
      user: user,
      local_authority: local_authority,
    )
  end

  let!(:in_assessment_planning_application) do
    create(
      :planning_application,
      :in_assessment,
      user: user,
      local_authority: local_authority,
    )
  end

  let!(:awaiting_determination_planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      user: user,
      local_authority: local_authority,
    )
  end

  let!(:awaiting_correction_planning_application) do
    create(
      :planning_application,
      :awaiting_correction,
      user: user,
      local_authority: local_authority,
    )
  end

  let!(:closed_planning_application) do
    create(
      :planning_application,
      :closed,
      user: user,
      local_authority: local_authority,
    )
  end

  let!(:other_closed_planning_application) do
    create(
      :planning_application,
      :closed,
      user: other_user,
      local_authority: local_authority,
    )
  end

  before { sign_in(user) }

  context "when user views her own planning applications" do
    before do
      visit(planning_applications_path)
      click_on "View my applications"
    end

    it "allows user to filter by different statuses" do
      within(selected_govuk_tab) do
        expect(page).to have_content("Your applications")
        expect(page).to have_content(not_started_planning_application.reference)
        expect(page).to have_content(invalid_planning_application.reference)
        expect(page).to have_content(in_assessment_planning_application.reference)
        expect(page).to have_content(awaiting_determination_planning_application.reference)
        expect(page).to have_content(awaiting_correction_planning_application.reference)
        expect(page).to have_content(closed_planning_application.reference)
        expect(page).not_to have_content(other_closed_planning_application.reference)
      end

      click_button("Filter by status (6 of 6 selected)")
      uncheck("Invalid")
      uncheck("In assessment")
      uncheck("Awaiting determination")
      uncheck("To be reviewed")
      uncheck("Closed")

      click_button("Apply filters")

      within(selected_govuk_tab) do
        expect(page).to have_content("(1 of 6 selected)")
        expect(page).to have_content(not_started_planning_application.reference)
        expect(page).not_to have_content(invalid_planning_application.reference)
        expect(page).not_to have_content(in_assessment_planning_application.reference)
        expect(page).not_to have_content(awaiting_determination_planning_application.reference)
        expect(page).not_to have_content(awaiting_correction_planning_application.reference)
        expect(page).not_to have_content(closed_planning_application.reference)
      end

      click_button("Filter by status (1 of 6 selected)")
      check("Invalid")
      uncheck("Not started")
      uncheck("In assessment")
      uncheck("Awaiting determination")
      uncheck("To be reviewed")
      uncheck("Closed")

      click_button("Apply filters")

      within(selected_govuk_tab) do
        expect(page).to have_content("(1 of 6 selected)")
        expect(page).to have_content(invalid_planning_application.reference)
        expect(page).not_to have_content(not_started_planning_application.reference)
        expect(page).not_to have_content(in_assessment_planning_application.reference)
        expect(page).not_to have_content(awaiting_determination_planning_application.reference)
        expect(page).not_to have_content(awaiting_correction_planning_application.reference)
        expect(page).not_to have_content(closed_planning_application.reference)
      end

      click_button("Filter by status (1 of 6 selected)")
      check("In assessment")
      uncheck("Not started")
      uncheck("Invalid")
      uncheck("Awaiting determination")
      uncheck("To be reviewed")
      uncheck("Closed")

      click_button("Apply filters")

      within(selected_govuk_tab) do
        expect(page).to have_content("(1 of 6 selected)")
        expect(page).to have_content(in_assessment_planning_application.reference)
        expect(page).not_to have_content(not_started_planning_application.reference)
        expect(page).not_to have_content(invalid_planning_application.reference)
        expect(page).not_to have_content(awaiting_determination_planning_application.reference)
        expect(page).not_to have_content(awaiting_correction_planning_application.reference)
        expect(page).not_to have_content(closed_planning_application.reference)
      end

      click_button("Filter by status (1 of 6 selected)")
      check("Awaiting determination")
      uncheck("Not started")
      uncheck("Invalid")
      uncheck("In assessment")
      uncheck("To be reviewed")
      uncheck("Closed")

      click_button("Apply filters")

      within(selected_govuk_tab) do
        expect(page).to have_content("(1 of 6 selected)")
        expect(page).to have_content(awaiting_determination_planning_application.reference)
        expect(page).not_to have_content(not_started_planning_application.reference)
        expect(page).not_to have_content(invalid_planning_application.reference)
        expect(page).not_to have_content(in_assessment_planning_application.reference)
        expect(page).not_to have_content(awaiting_correction_planning_application.reference)
        expect(page).not_to have_content(closed_planning_application.reference)
      end

      click_button("Filter by status (1 of 6 selected)")
      check("To be reviewed")
      uncheck("Not started")
      uncheck("Invalid")
      uncheck("In assessment")
      uncheck("Awaiting determination")
      uncheck("Closed")

      click_button("Apply filters")

      within(selected_govuk_tab) do
        expect(page).to have_content("(1 of 6 selected)")
        expect(page).to have_content(awaiting_correction_planning_application.reference)
        expect(page).not_to have_content(not_started_planning_application.reference)
        expect(page).not_to have_content(invalid_planning_application.reference)
        expect(page).not_to have_content(in_assessment_planning_application.reference)
        expect(page).not_to have_content(awaiting_determination_planning_application.reference)
        expect(page).not_to have_content(closed_planning_application.reference)
      end

      click_button("Filter by status (1 of 6 selected)")
      check("Closed")
      uncheck("Not started")
      uncheck("Invalid")
      uncheck("In assessment")
      uncheck("Awaiting determination")
      uncheck("To be reviewed")

      click_button("Apply filters")

      within(selected_govuk_tab) do
        expect(page).to have_content("(1 of 6 selected)")
        expect(page).to have_content(closed_planning_application.reference)
        expect(page).not_to have_content(other_closed_planning_application.reference)
        expect(page).not_to have_content(not_started_planning_application.reference)
        expect(page).not_to have_content(invalid_planning_application.reference)
        expect(page).not_to have_content(in_assessment_planning_application.reference)
        expect(page).not_to have_content(awaiting_determination_planning_application.reference)
        expect(page).not_to have_content(awaiting_correction_planning_application.reference)
      end
    end

    it "allows user to filter by many different statuses" do
      click_button("Filter by status (6 of 6 selected)")
      uncheck("Awaiting determination")
      uncheck("To be reviewed")
      uncheck("Closed")

      click_button("Apply filters")

      within(selected_govuk_tab) do
        expect(page).to have_content("(3 of 6 selected)")
        expect(page).to have_content(not_started_planning_application.reference)
        expect(page).to have_content(invalid_planning_application.reference)
        expect(page).to have_content(in_assessment_planning_application.reference)
        expect(page).not_to have_content(awaiting_determination_planning_application.reference)
        expect(page).not_to have_content(awaiting_correction_planning_application.reference)
        expect(page).not_to have_content(closed_planning_application.reference)
      end
    end
  end
end
