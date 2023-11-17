# frozen_string_literal: true

require "rails_helper"

RSpec.describe "searching planning applications" do
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
      description: "Add a chimney stack"
    )
  end

  let!(:planning_application2) do
    create(
      :planning_application,
      :in_assessment,
      user: nil,
      local_authority:,
      description: "Add a patio"
    )
  end

  let!(:planning_application3) do
    create(
      :planning_application,
      :to_be_reviewed,
      user: other_user,
      local_authority:,
      description: "Add a skylight"
    )
  end

  let(:govuk_tab_all) { find("div[class='govuk-tabs__panel']#all") }

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
      visit "/"
    end

    it "allows user to search planning applications by reference" do
      within(govuk_tab_all) do
        expect(page).to have_content("Your live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
        click_button("Search")
      end

      within(govuk_tab_all) do
        expect(page).to have_content("Your live applications")
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      within(govuk_tab_all) do
        fill_in("Find an application", with: "00100")
        click_button("Search")
      end

      within(govuk_tab_all) do
        expect(page).to have_content("Your live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      visit "/"
      visit "/planning_applications?#{query}#all"

      within(govuk_tab_all) do
        expect(page).to have_content("Your live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      within(govuk_tab_all) do
        click_link("Clear search")
        expect(find_field("Find an application").value).to eq("")
      end

      within(govuk_tab_all) do
        expect(page).to have_content("Your live applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "allows user to search on filtered results" do
      within(govuk_tab_all) do
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
      within(govuk_tab_all) do
        fill_in("Find an application", with: "chimney")
        click_button("Search")

        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
      end
    end

    it "allows user to clear form without submitting it" do
      within(govuk_tab_all) do
        fill_in("Find an application", with: "abc")
        click_link("Clear search")

        expect(find_field("Find an application").value).to eq("")

        expect(page).to have_content("Your live applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "shows message when there are no search results" do
      within(govuk_tab_all) do
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
    let(:query) {
      {
        query: "00100",
        view: "all",
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
      visit "/planning_applications"
      click_link("View all applications")

      within(govuk_tab_all) do
        click_link("Clear search")
      end
    end

    it "allows user to search planning applications by reference" do
      within(govuk_tab_all) do
        expect(page).to have_content("Live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)

        click_button("Search")

        expect(page).to have_content("Live applications")
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)

        fill_in("Find an application", with: "00100")
        click_button("Search")

        expect(page).to have_content("Live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      visit "/"
      visit "/planning_applications?#{query}#all"

      within(govuk_tab_all) do
        expect(page).to have_content("Live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)

        click_link("Clear search")

        expect(find_field("Find an application").value).to eq("")

        expect(page).to have_content("Live applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end
    end

    it "allows user to search planning applications by description" do
      within(govuk_tab_all) do
        fill_in("Find an application", with: "chimney")
        click_button("Search")

        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "allows user to search on filtered results" do
      within(govuk_tab_all) do
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
      within(govuk_tab_all) do
        fill_in("Find an application", with: "abc")
        click_link("Clear search")

        expect(find_field("Find an application").value).to eq("")
        expect(page).to have_content("Live applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end
    end

    it "shows message when there are no search results" do
      within(govuk_tab_all) do
        fill_in("Find an application", with: "something else entirely")
        click_button("Search")

        expect(page).to have_content("No planning applications match your search")
      end
    end
  end
end
