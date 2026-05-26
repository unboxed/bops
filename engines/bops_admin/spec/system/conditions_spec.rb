# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conditions", capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "paginates the conditions list" do
    25.times { create(:local_authority_condition, local_authority:) }

    visit "/admin/conditions"
    expect(page).to have_selector("h1", text: "Manage conditions")
    expect(page).to have_selector("tbody tr", count: 10)

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/conditions?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/conditions?page=2")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
      expect(page).to have_link("Previous", href: "/admin/conditions?page=1")
      expect(page).to have_link("Next", href: "/admin/conditions?page=3")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/conditions?page=3")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
      expect(page).to have_link("Previous", href: "/admin/conditions?page=2")
      expect(page).to have_no_link("Next")
    end
  end

  it "allows searching for an condition" do
    25.times { create(:local_authority_condition, local_authority:) }
    condition = create(:local_authority_condition, local_authority:, title: "Standard condition 1", text: "Standard condition 1 needs applying", reason: "Condition applies to this application type")

    visit "/admin/conditions"
    expect(page).to have_selector("h1", text: "Manage conditions")

    fill_in "Find condition", with: "Standard condition 1"

    click_button("Find condition")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Standard condition 1")
      expect(page).to have_selector("td:nth-child(2)", text: "Standard condition 1 needs applying")
      expect(page).to have_selector("td:nth-child(3)", text: "Condition applies to this application type")

      within "td:nth-child(4)" do
        expect(page).to have_link("Edit", href: "/admin/conditions/#{condition.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/conditions/#{condition.to_param}")
      end
    end
  end

  it "allows adding a condition" do
    visit "/admin/conditions"
    expect(page).to have_selector("h1", text: "Manage conditions")

    click_link("Add condition")
    expect(page).to have_selector("h1", text: "Add a new condition")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Enter Title", href: "#condition-title-field-error")
    expect(page).to have_link("Enter Text", href: "#condition-text-field-error")

    fill_in "Title", with: "Standard condition 1"
    fill_in "Condition", with: "Standard condition 1 needs applying"
    fill_in "Reason for condition", with: "Condition applies to this application type"

    click_button("Submit")
    expect(page).to have_current_path("/admin/conditions")
    expect(page).to have_content("Condition successfully created")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Standard condition 1")
      expect(page).to have_selector("td:nth-child(2)", text: "Standard condition 1 needs applying")
      expect(page).to have_selector("td:nth-child(3)", text: "Condition applies to this application type")
    end
  end

  it "allows editing an condition" do
    create(:local_authority_condition, local_authority:, title: "Standard condition 1", text: "Standard condition 1 needs applying", reason: "Condition applies to this application type")
    visit "/admin/conditions"
    expect(page).to have_selector("h1", text: "Manage conditions")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Standard condition 1")
      expect(page).to have_selector("td:nth-child(2)", text: "Standard condition 1 needs applying")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit condition")

    fill_in "Condition", with: "Condition 1 really needs adding"

    click_button("Submit")
    expect(page).to have_current_path("/admin/conditions")
    expect(page).to have_content("Condition successfully updated")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Standard condition 1")
      expect(page).to have_selector("td:nth-child(2)", text: "Condition 1 really needs adding")
      expect(page).to have_selector("td:nth-child(3)", text: "Condition applies to this application type")
    end
  end

  it "allows deleting an condition", :capybara do
    create(:local_authority_condition, local_authority:, title: "Section 106", text: "Section 106 needs doing")

    visit "/admin/conditions"
    expect(page).to have_selector("h1", text: "Manage conditions")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Section 106")

      accept_confirm do
        click_link("Delete")
      end
    end

    expect(page).to have_content("Condition successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No conditions found")
  end

  it "redirects to the first page if the page parameter overflows" do
    25.times { create(:local_authority_condition, local_authority:) }

    visit "/admin/conditions?page=2"
    expect(page).to have_selector("h1", text: "Manage conditions")
    expect(page).to have_current_path("/admin/conditions?page=2")

    visit "/admin/conditions?page=4"
    expect(page).to have_selector("h1", text: "Manage conditions")
    expect(page).to have_current_path("/admin/conditions")
  end
end
