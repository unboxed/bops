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
      user:,
      local_authority:,
      description: "Add a chimney stack"
    )
  end

  let!(:planning_application2) do
    create(
      :planning_application,
      user: nil,
      local_authority:,
      description: "Add a patio"
    )
  end

  let!(:planning_application3) do
    create(
      :planning_application,
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
      end

      click_button("Search")

      within(selected_govuk_tab) do
        expect(page).to have_content("Your live applications")
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      fill_in("Find an application", with: "00100")
      click_button("Search")

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

      click_link("Clear search")

      expect(find_field("Find an application").value).to eq("")

      within(selected_govuk_tab) do
        expect(page).to have_content("Your live applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "allows user to search planning applications by description" do
      fill_in("Find an application", with: "chimney")
      click_button("Search")

      within(selected_govuk_tab) do
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
      end
    end

    it "allows user to clear form without submitting it" do
      fill_in("Find an application", with: "abc")
      click_link("Clear search")

      expect(find_field("Find an application").value).to eq("")

      within(selected_govuk_tab) do
        expect(page).to have_content("Your live applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "shows message when there are no search results" do
      fill_in("Find an application", with: "something else entirely")
      click_button("Search")

      expect(page).to have_content("No planning applications match your search")
    end
  end

  context "when user views all planning applications" do
    before do
      visit(planning_applications_path)
      click_link("All applications")
    end

    it "allows user to search planning applications by reference" do
      within(selected_govuk_tab) do
        expect(page).to have_content("All applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end

      click_button("Search")

      within(selected_govuk_tab) do
        expect(page).to have_content("All applications")
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end

      fill_in("Find an application", with: "00100")
      click_button("Search")

      within(selected_govuk_tab) do
        expect(page).to have_content("All applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      search_url = current_url
      visit(root_path)
      visit(search_url)

      within(selected_govuk_tab) do
        expect(page).to have_content("All applications")
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      click_link("Clear search")

      expect(find_field("Find an application").value).to eq("")

      within(selected_govuk_tab) do
        expect(page).to have_content("All applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end
    end

    it "allows user to search planning applications by description" do
      fill_in("Find an application", with: "chimney")
      click_button("Search")

      within(selected_govuk_tab) do
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end

    it "allows user to clear form without submitting it" do
      fill_in("Find an application", with: "abc")
      click_link("Clear search")

      expect(find_field("Find an application").value).to eq("")

      within(selected_govuk_tab) do
        expect(page).to have_content("All applications")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end
    end

    it "shows message when there are no search results" do
      fill_in("Find an application", with: "something else entirely")
      click_button("Search")

      expect(page).to have_content("No planning applications match your search")
    end
  end
end
