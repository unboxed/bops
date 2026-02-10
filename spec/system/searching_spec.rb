# frozen_string_literal: true

require "rails_helper"

RSpec.describe "searching planning applications", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }

  let(:other_user) do
    create(:user, :assessor, local_authority:)
  end

  let!(:planning_application1) do
    create(
      :planning_application,
      :in_assessment,
      user:,
      local_authority:,
      description: "Add a chimney stack",
      address_1: "11 Abbey Gardens",
      address_2: "Southwark",
      town: "London",
      county: "Greater London",
      postcode: "SE16 3RQ"
    )
  end

  let!(:planning_application2) do
    create(
      :planning_application,
      :in_assessment,
      user: nil,
      local_authority:,
      description: "Add a patio",
      address_1: "140, WOODWARDE ROAD",
      address_2: "Dulwich",
      town: "London",
      county: "Greater London",
      postcode: "SE22 8UR"
    )
  end

  let!(:planning_application3) do
    create(
      :planning_application,
      :to_be_reviewed,
      user: other_user,
      local_authority:,
      description: "Add a skylight",
      address_1: "23 Abbey Gardens",
      address_2: "Southwark",
      town: "London",
      county: "Greater London",
      postcode: "SE16 3RQ"
    )
  end

  before { sign_in(user) }

  context "when user views her own planning applications" do
    let(:query) {
      {
        query: "00100",
        submit: "search",
        application_type: %w[
          prior_approval planning_permission lawfulness_certificate
        ],
        status: %w[
          not_started invalidated in_assessment awaiting_determination to_be_reviewed
        ]
      }.to_query
    }

    before do
      visit "/planning_applications/mine"
    end

    it "allows user to search planning applications by reference" do
      within(selected_govuk_tab) do
        expect(page).to have_content("My applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)

        click_button("Search")
        expect(page).to have_current_path(%r{^/planning_applications/mine\?query=&submit=search})

        expect(page).to have_content("My applications")
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)

        fill_in("Find an application", with: "00100")

        click_button("Search")
        expect(page).to have_current_path(%r{^/planning_applications/mine\?query=00100&submit=search})

        expect(page).to have_content("My applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      expect(page).to have_css(".govuk-service-navigation")
      expect(page).to have_link("Pre-application")
      expect(page).to have_link("Planning")
      expect(page).to have_link("Enforcement")

      visit "/"
      visit "/planning_applications/mine?#{query}"

      within(selected_govuk_tab) do
        expect(page).to have_content("My applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)

        click_link("Clear search")
        expect(page).to have_field("Find an application", with: "")

        expect(page).to have_content("My applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      click_link "Unassigned cases"
      within(selected_govuk_tab) do
        expect(page).to have_content("Unassigned applications")
        expect(page).not_to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "allows user to search on filtered results" do
      click_link "All cases"

      within(selected_govuk_tab) do
        click_button("Filter")
        uncheck("Invalid")
        uncheck("Not started")
        uncheck("Awaiting determination")
        uncheck("To be reviewed")

        click_button("Apply filters")

        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)

        fill_in("Find an application", with: "chimney")
        click_button("Search")

        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
      end
    end

    it "allows user to search planning applications by description" do
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "chimney")
        click_button("Search")

        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
      end
    end

    describe "searching for applications using an address" do
      before do
        click_link "All cases"
      end

      context "when using: '11 Abbey Gardens'" do
        it "returns the correct results" do
          within(selected_govuk_tab) do
            fill_in("Find an application", with: "11 Abbey Gardens")

            click_button("Search")
            expect(page).to have_current_path(%r{^/planning_applications/all\?query=11\+Abbey\+Gardens})

            expect(page).to have_content(planning_application1.reference)
            expect(page).not_to have_content(planning_application2.reference)
            expect(page).not_to have_content(planning_application3.reference)
          end
        end
      end

      context "when using: '20 Abbey Gardens'" do
        it "returns the correct results" do
          within(selected_govuk_tab) do
            fill_in("Find an application", with: "20 Abbey Gardens")

            click_button("Search")
            expect(page).to have_current_path(%r{^/planning_applications/all\?query=20\+Abbey\+Gardens})

            expect(page).not_to have_content(planning_application1.reference)
            expect(page).not_to have_content(planning_application2.reference)
            expect(page).not_to have_content(planning_application3.reference)
          end
        end
      end

      context "when using: 'GARDENS'" do
        it "returns the correct results" do
          within(selected_govuk_tab) do
            fill_in("Find an application", with: "GARDENS")

            click_button("Search")
            expect(page).to have_current_path(%r{^/planning_applications/all\?query=GARDENS})

            expect(page).to have_content(planning_application1.reference)
            expect(page).not_to have_content(planning_application2.reference)
            expect(page).to have_content(planning_application3.reference)
          end
        end
      end

      context "when using: '140 woodwarde'" do
        it "returns the correct results" do
          within(selected_govuk_tab) do
            fill_in("Find an application", with: "140 woodwarde")

            click_button("Search")
            expect(page).to have_current_path(%r{^/planning_applications/all\?query=140\+woodwarde})

            expect(page).not_to have_content(planning_application1.reference)
            expect(page).to have_content(planning_application2.reference)
            expect(page).not_to have_content(planning_application3.reference)
          end
        end
      end

      context "when using: 'london'" do
        it "returns the correct results" do
          within(selected_govuk_tab) do
            fill_in("Find an application", with: "london")

            click_button("Search")
            expect(page).to have_current_path(%r{^/planning_applications/all\?query=london})

            expect(page).to have_content(planning_application1.reference)
            expect(page).to have_content(planning_application2.reference)
            expect(page).to have_content(planning_application3.reference)
          end
        end
      end

      context "when using: 'southwark'" do
        it "returns the correct results" do
          click_link "All cases"

          within(selected_govuk_tab) do
            fill_in("Find an application", with: "southwark")

            click_button("Search")
            expect(page).to have_current_path(%r{^/planning_applications/all\?query=southwark})

            expect(page).to have_content(planning_application1.reference)
            expect(page).not_to have_content(planning_application2.reference)
            expect(page).to have_content(planning_application3.reference)
          end
        end
      end

      context "when using: 'se22 8UR'" do
        it "returns the correct results" do
          within(selected_govuk_tab) do
            fill_in("Find an application", with: "se22 8UR")

            click_button("Search")
            expect(page).to have_current_path(%r{^/planning_applications/all\?query=se22\+8UR})

            expect(page).not_to have_content(planning_application1.reference)
            expect(page).to have_content(planning_application2.reference)
            expect(page).not_to have_content(planning_application3.reference)
          end
        end
      end

      context "when using: 'se22 8UR'" do
        it "returns the correct results" do
          within(selected_govuk_tab) do
            fill_in("Find an application", with: "sE228uR")

            click_button("Search")
            expect(page).to have_current_path(%r{^/planning_applications/all\?query=sE228uR})

            expect(page).not_to have_content(planning_application1.reference)
            expect(page).to have_content(planning_application2.reference)
            expect(page).not_to have_content(planning_application3.reference)
          end
        end
      end
    end

    it "allows user to clear form without submitting it" do
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "abc")

        click_link("Clear search")
        expect(page).to have_field("Find an application", with: "")

        expect(page).to have_content("My applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "shows message when there are no search results" do
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "something else entirely")
        click_button("Search")

        expect(page).to have_content("No planning applications match your search")
      end
    end

    it "allows user to search using the status indicators" do
      find_by_id("reviewer-requests").click
      expect(page).to have_css("#reviewer-requests.status-panel--highlighted")
    end

    it "allows user to deselect the status indicators" do
      find_by_id("reviewer-requests").click
      find_by_id("reviewer-requests").click
      expect(page).not_to have_css("#reviewer-requests.status-panel--highlighted")
    end
  end

  context "when user views all planning applications" do
    let(:empty_query) {
      %w[
        query=
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
    }

    let(:query) {
      %w[
        query=00100
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
    }

    before do
      visit "/planning_applications"
      click_link("All cases")

      within(selected_govuk_tab) do
        click_link("Clear search")
        expect(page).to have_field("Find an application", with: "")
      end
    end

    it "allows user to search planning applications by reference" do
      within(selected_govuk_tab) do
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)

        click_button("Search")
        expect(page).to have_current_path("/planning_applications/all?#{empty_query}")

        expect(page).to have_content("All applications")
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)

        fill_in("Find an application", with: "00100")

        click_button("Search")
        expect(page).to have_current_path("/planning_applications/all?#{query}")

        expect(page).to have_content("All applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      visit "/"
      visit "/planning_applications/all?#{query}"

      within(selected_govuk_tab) do
        expect(page).to have_content("All applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)

        click_link("Clear search")
        expect(page).to have_field("Find an application", with: "")

        expect(page).to have_content("All applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end
    end

    it "allows user to search planning applications by description" do
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "chimney")

        click_button("Search")
        expect(page).to have_current_path(%r{^/planning_applications/all\?query=chimney})

        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "allows user to search on filtered results" do
      within(selected_govuk_tab) do
        click_button("Filter")
        uncheck("Invalid")
        uncheck("Not started")
        uncheck("Awaiting determination")
        uncheck("To be reviewed")

        click_button("Apply filters")

        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)

        fill_in("Find an application", with: "skylight")
        click_button("Search")

        expect(page).not_to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)

        expect(page).to have_content("No planning applications match your search")
      end
    end

    it "allows user to clear form without submitting it" do
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "abc")

        click_link("Clear search")
        expect(page).to have_field("Find an application", with: "")

        expect(page).to have_content("All applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end
    end

    it "shows message when there are no search results" do
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "something else entirely")

        click_button("Search")

        expect(page).to have_current_path(%r{^/planning_applications/all\?query=something\+else\+entirely})
        expect(page).to have_content("No planning applications match your search")
      end
    end
  end

  context "when an application is in assessment_in_progress status" do
    let!(:in_progress_application) do
      create(
        :planning_application,
        :assessment_in_progress,
        :planning_permission,
        user:,
        local_authority:,
        description: "Replacement of all windows",
        address_1: "3, WAVEL MEWS",
        address_2: "",
        town: "LONDON",
        county: "",
        postcode: "NW6 3AB"
      )
    end

    it "appears on the All cases tab with default filters" do
      visit "/planning_applications"
      click_link "All cases"

      within(selected_govuk_tab) do
        expect(page).to have_content(in_progress_application.reference)
      end
    end

    it "appears when filtering by In assessment only" do
      visit "/planning_applications"
      click_link "All cases"

      within(selected_govuk_tab) do
        click_button("Filter")
        uncheck("Not started")
        uncheck("Invalid")
        uncheck("Awaiting determination")
        uncheck("To be reviewed")

        click_button("Apply filters")

        expect(page).to have_content(in_progress_application.reference)
      end
    end

    it "is findable by reference search with default filters" do
      visit "/planning_applications"
      click_link "All cases"

      within(selected_govuk_tab) do
        fill_in("Find an application", with: in_progress_application.reference)
        click_button("Search")

        expect(page).to have_content(in_progress_application.reference)
      end
    end
  end
end
