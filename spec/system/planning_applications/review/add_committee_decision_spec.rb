# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add committee decision" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) do
    create(:user,
      :reviewer,
      local_authority: default_local_authority)
  end
  let!(:assessor) do
    create(:user,
      :assessor,
      local_authority: default_local_authority)
  end
  let!(:planning_application) do
    create(:planning_application, :in_committee, local_authority: default_local_authority, user: assessor)
  end

  before do
    allow(Current).to receive(:user).and_return(reviewer)

    sign_in reviewer
  end

  context "when the assessor has not recommended the application go to committee" do
    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, local_authority: default_local_authority, user: assessor)
    end

    before do
      create(:recommendation, planning_application:)
    end

    it "does not show the option to add committee decision" do
      visit "/planning_applications/#{planning_application.id}/review/tasks"

      expect(page).to have_content("Review and sign-off")

      expect(page).not_to have_content "Add committee decision"
    end
  end

  context "when the assessor has recommended the application go to committee" do
    context "when the committee agrees with the assessor" do
      it "can add what the committee decided" do
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Add committee decision",
          with: "Not started"
        )

        click_link "Add committee decision"

        expect(page).to have_content "Add committee decision"

        choose "Yes"

        click_button "Save and mark as complete"

        expect(page).to have_content "Recommendation was successfully reviewed"
        expect(page).to have_content "Awaiting determination"

        expect(page).to have_list_item_for(
          "Add committee decision",
          with: "Completed"
        )
      end
    end

    context "when the committee agrees with the assessor but needs amendments" do
      it "can add what the committee decided" do
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Add committee decision",
          with: "Not started"
        )

        click_link "Add committee decision"

        expect(page).to have_content "Add committee decision"

        choose "Yes, with amendments (return to case officer)"

        fill_in "Explain to the officer why the case is being returned", with: "Committee wants more conditions"

        click_button "Save and mark as complete"

        expect(page).to have_content "Recommendation was successfully reviewed"
        expect(page).to have_content "To be reviewed"

        expect(page).to have_list_item_for(
          "Add committee decision",
          with: "Completed"
        )
      end

      it "shows errors" do
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        click_link "Add committee decision"

        expect(page).to have_content "Add committee decision"

        choose "Yes, with amendments (return to case officer)"

        click_button "Save and mark as complete"

        expect(page).to have_content "Explain to the case officer why the recommendation has been challenged."
      end
    end

    context "when the committee disagrees with the assessor's recommendation" do
      it "can add what the committee decided" do
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Add committee decision",
          with: "Not started"
        )

        click_link "Add committee decision"

        expect(page).to have_content "Add committee decision"

        choose "No"

        click_button "Save and mark as complete"

        expect(page).to have_content "Add committee decision details"
        choose "Refused"

        fill_in "Public comment", with: "This is the comment"

        click_button "Save and mark as complete"

        expect(page).to have_content "Details of committee decisison successully added"
        expect(page).to have_content "Awaiting determination"

        expect(page).to have_list_item_for(
          "Add committee decision",
          with: "Completed"
        )
      end

      it "shows errors" do
        visit "/planning_applications/#{planning_application.id}/review/tasks"

        expect(page).to have_list_item_for(
          "Add committee decision",
          with: "Not started"
        )

        click_link "Add committee decision"

        expect(page).to have_content "Add committee decision"

        choose "No"

        click_button "Save and mark as complete"

        expect(page).to have_content "Add committee decision details"

        click_button "Save and mark as complete"

        expect(page).to have_content "Select 'refused' or 'granted' to record your recommendation"
      end
    end
  end
end
