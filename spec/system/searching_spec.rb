# frozen_string_literal: true

require "rails_helper"

RSpec.describe "searching planning applications", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority: local_authority) }

  let(:other_user) do
    create(:user, :assessor, local_authority: local_authority)
  end

  let!(:planning_application1) do
    create(:planning_application, user: user, local_authority: local_authority)
  end

  let!(:planning_application2) do
    create(:planning_application, user: nil, local_authority: local_authority)
  end

  let!(:planning_application3) do
    create(
      :planning_application,
      user: other_user,
      local_authority: local_authority
    )
  end

  before { sign_in(user) }

  context "when users views her own planning applications" do
    it "allows user to search planning applications by reference" do
      visit(planning_applications_path(q: "exclude_others"))
      click_link("All your applications")

      selected_tab = find("div[class='govuk-tabs__panel']")
      expect(selected_tab).to have_content("All your applications")

      within(selected_tab) do
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      click_button("Search")

      selected_tab = find("div[class='govuk-tabs__panel']")
      expect(selected_tab).to have_content("All your applications")

      within(selected_tab) do
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      fill_in("Find an application", with: "00100")
      click_button("Search")

      selected_tab = find("div[class='govuk-tabs__panel']")
      expect(selected_tab).to have_content("All your applications")

      within(selected_tab) do
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      search_url = current_url
      visit(root_path)
      visit(search_url)

      selected_tab = find("div[class='govuk-tabs__panel']")
      expect(selected_tab).to have_content("All your applications")

      within(selected_tab) do
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end
  end

  context "when user views all planning applications" do
    it "allows user to search planning applications by reference" do
      visit(planning_applications_path)
      click_link("All applications")

      selected_tab = find("div[class='govuk-tabs__panel']")
      expect(selected_tab).to have_content("All applications")

      within(selected_tab) do
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end

      click_button("Search")

      selected_tab = find("div[class='govuk-tabs__panel']")
      expect(selected_tab).to have_content("All applications")

      within(selected_tab) do
        expect(page).to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).to have_content(planning_application2.reference)
        expect(page).to have_content(planning_application3.reference)
      end

      fill_in("Find an application", with: "00100")
      click_button("Search")

      selected_tab = find("div[class='govuk-tabs__panel']")
      expect(selected_tab).to have_content("All applications")

      within(selected_tab) do
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end

      search_url = current_url
      visit(root_path)
      visit(search_url)

      selected_tab = find("div[class='govuk-tabs__panel']")
      expect(selected_tab).to have_content("All applications")

      within(selected_tab) do
        expect(page).not_to have_content("Query can't be blank")
        expect(page).to have_content(planning_application1.reference)
        expect(page).not_to have_content(planning_application2.reference)
        expect(page).not_to have_content(planning_application3.reference)
      end
    end
  end
end
