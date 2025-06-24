# frozen_string_literal: true

require "rails_helper"

RSpec.describe "filtering planning applications", type: :system, capybara: true do
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

  let!(:other_user_in_assessment_planning_application) do
    create(
      :planning_application,
      :in_assessment,
      user: other_user,
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

      describe "filtering by different statuses" do
        before do
          within(selected_govuk_tab) do
            expect(page).to have_content("My applications")
            expect(page).to have_content(not_started_planning_application.reference)
            expect(page).to have_content(invalid_planning_application.reference)
            expect(page).to have_content(in_assessment_planning_application.reference)
            expect(page).to have_content(awaiting_determination_planning_application.reference)
            expect(page).to have_content(to_be_reviewed_planning_application.reference)
            expect(page).not_to have_content(closed_planning_application.reference)
            expect(page).not_to have_content(other_closed_planning_application.reference)
          end
        end

        it "allows viewing 'Not started' applications" do
          within(selected_govuk_tab) do
            click_button("Filter")
            check("Not started")
            uncheck("Invalid")
            uncheck("In assessment")
            uncheck("Awaiting determination")
            uncheck("To be reviewed")

            click_button("Apply filters")
            expect(page).to have_current_path("/planning_applications", ignore_query: true)

            expect(page).to have_content(not_started_planning_application.reference)
            expect(page).not_to have_content(invalid_planning_application.reference)
            expect(page).not_to have_content(in_assessment_planning_application.reference)
            expect(page).not_to have_content(awaiting_determination_planning_application.reference)
            expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
            expect(page).not_to have_content(closed_planning_application.reference)
          end
        end

        it "allows viewing 'Invalid' applications" do
          within(selected_govuk_tab) do
            click_button("Filter")
            uncheck("Not started")
            check("Invalid")
            uncheck("In assessment")
            uncheck("Awaiting determination")
            uncheck("To be reviewed")

            click_button("Apply filters")
            expect(page).to have_current_path("/planning_applications", ignore_query: true)

            expect(page).not_to have_content(not_started_planning_application.reference)
            expect(page).to have_content(invalid_planning_application.reference)
            expect(page).not_to have_content(in_assessment_planning_application.reference)
            expect(page).not_to have_content(awaiting_determination_planning_application.reference)
            expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
            expect(page).not_to have_content(closed_planning_application.reference)
          end
        end

        it "allows viewing 'In assessment' applications" do
          within(selected_govuk_tab) do
            click_button("Filter")
            uncheck("Not started")
            uncheck("Invalid")
            check("In assessment")
            uncheck("Awaiting determination")
            uncheck("To be reviewed")

            click_button("Apply filters")
            expect(page).to have_current_path("/planning_applications", ignore_query: true)

            expect(page).not_to have_content(not_started_planning_application.reference)
            expect(page).not_to have_content(invalid_planning_application.reference)
            expect(page).to have_content(in_assessment_planning_application.reference)
            expect(page).not_to have_content(awaiting_determination_planning_application.reference)
            expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
            expect(page).not_to have_content(closed_planning_application.reference)
          end
        end

        it "allows viewing 'Awaiting determination' applications" do
          within(selected_govuk_tab) do
            click_button("Filter")
            uncheck("Not started")
            uncheck("Invalid")
            uncheck("In assessment")
            check("Awaiting determination")
            uncheck("To be reviewed")

            click_button("Apply filters")
            expect(page).to have_current_path("/planning_applications", ignore_query: true)

            expect(page).not_to have_content(not_started_planning_application.reference)
            expect(page).not_to have_content(invalid_planning_application.reference)
            expect(page).not_to have_content(in_assessment_planning_application.reference)
            expect(page).to have_content(awaiting_determination_planning_application.reference)
            expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
            expect(page).not_to have_content(closed_planning_application.reference)
          end
        end

        it "allows viewing 'To be reviewed' applications" do
          within(selected_govuk_tab) do
            click_button("Filter")
            uncheck("Not started")
            uncheck("Invalid")
            uncheck("In assessment")
            uncheck("Awaiting determination")
            check("To be reviewed")

            click_button("Apply filters")
            expect(page).to have_current_path("/planning_applications", ignore_query: true)

            expect(page).not_to have_content(not_started_planning_application.reference)
            expect(page).not_to have_content(invalid_planning_application.reference)
            expect(page).not_to have_content(in_assessment_planning_application.reference)
            expect(page).not_to have_content(awaiting_determination_planning_application.reference)
            expect(page).to have_content(to_be_reviewed_planning_application.reference)
            expect(page).not_to have_content(closed_planning_application.reference)
          end
        end

        it "allows viewing 'Closed' applications" do
          click_link("Closed")

          within(selected_govuk_tab) do
            expect(page).not_to have_content(other_closed_planning_application.reference)
            expect(page).not_to have_content(not_started_planning_application.reference)
            expect(page).not_to have_content(invalid_planning_application.reference)
            expect(page).not_to have_content(in_assessment_planning_application.reference)
            expect(page).not_to have_content(awaiting_determination_planning_application.reference)
            expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
            expect(page).to have_content(closed_planning_application.reference)
          end
        end
      end

      it "allows user to filter by many different statuses" do
        within(selected_govuk_tab) do
          click_button("Filter")
          expect(page).to have_selector(:open_accordion, text: "Filters")

          uncheck("Awaiting determination")
          uncheck("To be reviewed")

          query = %w[
            query=
            application_type%5B%5D=
            application_type%5B%5D=prior_approval
            application_type%5B%5D=planning_permission
            application_type%5B%5D=lawfulness_certificate
            application_type%5B%5D=pre_application
            application_type%5B%5D=other
            status%5B%5D=
            status%5B%5D=not_started
            status%5B%5D=invalidated
            status%5B%5D=in_assessment
          ].join("&")

          click_button("Apply filters")
          expect(page).to have_current_path("/planning_applications?#{query}")

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

          query = %w[
            query=Chimney
            submit=search
            application_type%5B%5D=
            application_type%5B%5D=prior_approval
            application_type%5B%5D=planning_permission
            application_type%5B%5D=lawfulness_certificate
            application_type%5B%5D=pre_application
            application_type%5B%5D=other
            status%5B%5D=
            status%5B%5D=not_started
            status%5B%5D=invalidated
            status%5B%5D=in_assessment
            status%5B%5D=awaiting_determination
            status%5B%5D=to_be_reviewed
          ].join("&")

          click_button("Search")
          expect(page).to have_current_path("/planning_applications?#{query}")

          expect(page).to have_content(not_started_planning_application.reference)
          expect(page).to have_content(invalid_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)

          query = %w[
            query=Chimney
            submit=search
            application_type%5B%5D=
            application_type%5B%5D=prior_approval
            application_type%5B%5D=planning_permission
            application_type%5B%5D=lawfulness_certificate
            application_type%5B%5D=pre_application
            application_type%5B%5D=other
            status%5B%5D=
            status%5B%5D=not_started
            status%5B%5D=invalidated
            status%5B%5D=in_assessment
            status%5B%5D=awaiting_determination
            status%5B%5D=to_be_reviewed
          ].join("&")

          click_button("Filter")
          expect(page).to have_current_path("/planning_applications?#{query}")

          uncheck("Invalidated")
          uncheck("To be reviewed")

          query = %w[
            query=Chimney
            application_type%5B%5D=
            application_type%5B%5D=prior_approval
            application_type%5B%5D=planning_permission
            application_type%5B%5D=lawfulness_certificate
            application_type%5B%5D=pre_application
            application_type%5B%5D=other
            status%5B%5D=
            status%5B%5D=not_started
            status%5B%5D=in_assessment
            status%5B%5D=awaiting_determination
          ].join("&")

          click_button("Apply filters")
          expect(page).to have_current_path("/planning_applications?#{query}")

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
        visit "/#all"
      end

      it "allows user to filter by different statuses" do
        within(selected_govuk_tab) do
          expect(page).to have_content("All applications")
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
          # expect(page).to have_content(other_closed_planning_application.reference)
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
          expect(page).to have_content("My applications")
          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).to have_content(other_to_be_reviewed_planning_application.reference)
          expect(page).to have_content(other_user_in_assessment_planning_application.reference)
          expect(page).not_to have_content(in_assessment_planning_application.reference)
          expect(page).not_to have_content(closed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

          click_button("Filter")
          uncheck("To be reviewed")

          click_button("Apply filters")

          expect(page).to have_content(other_awaiting_determination_planning_application.reference)
          expect(page).not_to have_content(other_to_be_reviewed_planning_application.reference)
          expect(page).not_to have_content(other_closed_planning_application.reference)

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
        visit "/#all"
      end

      it "allows user to filter by different statuses" do
        within(selected_govuk_tab) do
          expect(page).to have_content("All applications")
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
          # expect(page).to have_content(closed_planning_application.reference)
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
