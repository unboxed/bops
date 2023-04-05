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

  before { sign_in(user) }

  context "when user views her own planning applications" do
    before do
      visit(root_path)
    end

    it "allows user to search planning applications by reference" do
      within(selected_govuk_tab) do
        expect(page).to have_content("Your live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
        click_button("Search")
      end

      within(selected_govuk_tab) do
        expect(page).to have_content("Your live applications")
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      within(selected_govuk_tab) do
        fill_in("Find an application", with: "00100")
        click_button("Search")
      end

      within(selected_govuk_tab) do
        expect(page).to have_content("Your live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      search_url = current_url
      visit(root_path)
      visit(search_url)

      within(selected_govuk_tab) do
        expect(page).to have_content("Your live applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      within(selected_govuk_tab) do
        click_link("Clear search")
        expect(find_field("Find an application").value).to eq("")
      end

      within(selected_govuk_tab) do
        expect(page).to have_content("Your live applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "allows user to search on filtered results" do
      within(selected_govuk_tab) do
        click_button("Filter by status (5 of 5 selected)")
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

    it "allows user to clear form without submitting it" do
      within(selected_govuk_tab) do
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
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "something else entirely")
        click_button("Search")

        expect(page).to have_content("No planning applications match your search")
      end
    end
  end

  context "when user views all planning applications" do
    before do
      visit(planning_applications_path)
      click_link("Live applications")

      within(selected_govuk_tab) do
        click_link("Clear search")
      end
    end

    it "allows user to search planning applications by reference" do
      within(selected_govuk_tab) do
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

      search_url = current_url
      visit(root_path)
      visit(search_url)

      within(selected_govuk_tab) do
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
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "chimney")
        click_button("Search")

        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "allows user to search on filtered results" do
      within(selected_govuk_tab) do
        click_button("Filter by status (5 of 5 selected)")
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

        expect(find_field("Find an application").value).to eq("")
        expect(page).to have_content("Live applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end
    end

    it "shows message when there are no search results" do
      within(selected_govuk_tab) do
        fill_in("Find an application", with: "something else entirely")
        click_button("Search")

        expect(page).to have_content("No planning applications match your search")
      end
    end
  end
end
