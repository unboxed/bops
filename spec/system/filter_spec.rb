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

  let!(:to_be_reviewed_planning_application) do
    create(
      :planning_application,
      :to_be_reviewed,
      user:,
      local_authority:
    )
  end

  let!(:other_to_be_reviewed_planning_application) do
    create(
      :planning_application,
      :to_be_reviewed,
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
        visit "/"
      end

      it "allows user to filter by different statuses" do
        within(selected_govuk_tab) do
          expect(page).to have_content("Your live applications")
          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).to have_content(in_assessment_planning_application.reference)
          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).to have_content(to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter")
          uncheck("Invalid")
          uncheck("In assessment")
          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter")
          check("Invalid")
          uncheck("Not started")
          uncheck("In assessment")
          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter")
          check("In assessment")
          uncheck("Not started")
          uncheck("Invalid")
          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter")
          check("Awaiting determination")
          uncheck("Not started")
          uncheck("Invalid")
          uncheck("In assessment")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter")
          check("To be reviewed")
          uncheck("Not started")
          uncheck("Invalid")
          uncheck("In assessment")
          uncheck("Awaiting determination")

          click_button("Apply filters")

          expect(page).to have_content(to_be_reviewed_planning_application.reference)
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
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
        end
      end

      it "allows user to filter by many different statuses" do
        within(selected_govuk_tab) do
          click_button("Filter")
          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
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
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          click_button("Filter")
          uncheck("Invalidated")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).not_to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
        end
      end
    end

    context "when looking at all applications" do
      before do
        sign_in(user)
        visit "/"
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
          expect(page).to have_content(to_be_reviewed_planning_application.reference)
          expect(page).to have_content(other_to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter")
          uncheck("Invalid")
          uncheck("In assessment")

          click_button("Apply filters")

          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(to_be_reviewed_planning_application.reference)
          expect(page).to have_content(other_to_be_reviewed_planning_application.reference)
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
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
        end
      end
    end
  end

  context "when user is reviewer" do
    context "when looking at their own applications" do
      before do
        sign_in(other_user)
        visit "/"
      end

      it "allows user to filter by different statuses" do
        within(selected_govuk_tab) do
          expect(page).to have_content("Your live applications")
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(other_to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter")
          check("To be reviewed")
          uncheck("Awaiting determination")

          click_button("Apply filters")

          expect(page).to have_content(other_to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)
        end

        click_link("Closed")

        within(selected_govuk_tab) do
          expect(page).to have_content(other_closed_planning_application.reference)
          expect(page).not_to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(other_to_be_reviewed_planning_application.reference)
        end
      end
    end

    context "when looking at all applications" do
      before do
        sign_in(other_user)
        visit "/"
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
          expect(page).to have_content(to_be_reviewed_planning_application.reference)
          expect(page).to have_content(other_to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter")
          uncheck("Invalid")
          uncheck("In assessment")

          click_button("Apply filters")

          expect(page).to have_content(awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(to_be_reviewed_planning_application.reference)
          expect(page).to have_content(other_to_be_reviewed_planning_application.reference)
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
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
        end
      end
    end
  end
end
