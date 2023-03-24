# frozen_string_literal: true

require "rails_helper"

RSpec.describe "filtering planning applications" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }

  let(:other_user) { create(:user, :reviewer, local_authority:) }

  let!(:not_started_planning_application) do
    create(
      :planning_application,
      :not_started,
      user:,
      local_authority:,
      description: "Chimney"
    )
  end

  let!(:invalid_planning_application) do
    create(
      :planning_application,
      :invalidated,
      user:,
      local_authority:,
      description: "Chimney"
    )
  end

  let!(:in_assessment_planning_application) do
    create(
      :planning_application,
      :in_assessment,
      user:,
      local_authority:
    )
  end

  let!(:awaiting_determination_planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      user:,
      local_authority:
    )
  end

  let!(:other_awaiting_determination_planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      user: other_user,
      local_authority:
    )
  end

  let!(:awaiting_correction_planning_application) do
    create(
      :planning_application,
      :awaiting_correction,
      user:,
      local_authority:
    )
  end

  let!(:other_awaiting_correction_planning_application) do
    create(
      :planning_application,
      :awaiting_correction,
      user: other_user,
      local_authority:
    )
  end

  let!(:closed_planning_application) do
    create(
      :planning_application,
      :closed,
      user:,
      local_authority:
    )
  end

  let!(:other_closed_planning_application) do
    create(
      :planning_application,
      :closed,
      user: other_user,
      local_authority:
    )
  end

  context "when user is assessor" do
    context "when looking at their own applications" do
      before do
        sign_in(user)
        visit(root_path)
      end

      it "allows user to filter by different statuses" do
        within(selected_govuk_tab) do
          expect(page).to have_content("Your live applications")
          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).to have_content(in_assessment_planning_application.reference)
          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter by status (5 of 5 selected)")
          uncheck("Invalid")
          uncheck("In assessment")
          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content("(1 of 5 selected)")
          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter by status (1 of 5 selected)")
          check("Invalid")
          uncheck("Not started")
          uncheck("In assessment")
          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content("(1 of 5 selected)")
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter by status (1 of 5 selected)")
          check("In assessment")
          uncheck("Not started")
          uncheck("Invalid")
          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content("(1 of 5 selected)")
          expect(page).to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter by status (1 of 5 selected)")
          check("Awaiting determination")
          uncheck("Not started")
          uncheck("Invalid")
          uncheck("In assessment")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content("(1 of 5 selected)")
          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter by status (1 of 5 selected)")
          check("To be reviewed")
          uncheck("Not started")
          uncheck("Invalid")
          uncheck("In assessment")
          uncheck("Awaiting determination")

          click_button("Apply filters")

          expect(page).to have_content("(1 of 5 selected)")
          expect(page).to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
        end

        click_link("Closed")

        within(selected_govuk_tab) do
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
        within(selected_govuk_tab) do
          click_button("Filter by status (5 of 5 selected)")
          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content("(3 of 5 selected)")
          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
        end
      end

      it "allows user to filter on searched results" do
        within(selected_govuk_tab) do
          fill_in("Find an application", with: "Chimney")
          click_button("Search")

          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter by status (5 of 5 selected)")
          uncheck("Invalidated")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
        end
      end
    end

    context "when looking at all applications" do
      before do
        sign_in(user)
        visit(root_path)
        click_link "View all applications"
      end

      it "allows user to filter by different statuses" do
        within(selected_govuk_tab) do
          expect(page).to have_content("Live applications")
          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).to have_content(in_assessment_planning_application.reference)
          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(awaiting_correction_planning_application.reference)
          expect(page).to have_content(other_awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter by status (5 of 5 selected)")
          uncheck("Invalid")
          uncheck("In assessment")

          click_button("Apply filters")

          expect(page).to have_content("(3 of 5 selected)")
          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(awaiting_correction_planning_application.reference)
          expect(page).to have_content(other_awaiting_correction_planning_application.reference)
          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
        end

        click_link("Closed")

        within(selected_govuk_tab) do
          expect(page).to have_content(closed_planning_application.reference)
          expect(page).to have_content(other_closed_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
        end
      end
    end
  end

  context "when user is reviewer" do
    context "when looking at their own applications" do
      before do
        sign_in(other_user)
        visit(root_path)
      end

      it "allows user to filter by different statuses" do
        within(selected_govuk_tab) do
          expect(page).to have_content("Your live applications")
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter by status (2 of 2 selected)")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content("(1 of 2 selected)")
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(other_awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter by status (1 of 2 selected)")
          check("To be reviewed")
          uncheck("Awaiting determination")

          click_button("Apply filters")

          expect(page).to have_content("(1 of 2 selected)")
          expect(page).to have_content(other_awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)
        end

        click_link("Closed")

        within(selected_govuk_tab) do
          expect(page).to have_content(other_closed_planning_application.reference)
          expect(page).not_to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(other_awaiting_correction_planning_application.reference)
        end
      end
    end

    context "when looking at all applications" do
      before do
        sign_in(other_user)
        visit(root_path)
        click_link "View all applications"
      end

      it "allows user to filter by different statuses" do
        within(selected_govuk_tab) do
          expect(page).to have_content("Live applications")
          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).to have_content(in_assessment_planning_application.reference)
          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(awaiting_correction_planning_application.reference)
          expect(page).to have_content(other_awaiting_correction_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter by status (5 of 5 selected)")
          uncheck("Invalid")
          uncheck("In assessment")

          click_button("Apply filters")

          expect(page).to have_content("(3 of 5 selected)")
          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(awaiting_correction_planning_application.reference)
          expect(page).to have_content(other_awaiting_correction_planning_application.reference)
          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
        end

        click_link("Closed")

        within(selected_govuk_tab) do
          expect(page).to have_content(closed_planning_application.reference)
          expect(page).to have_content(other_closed_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(awaiting_correction_planning_application.reference)
        end
      end
    end
  end
end
