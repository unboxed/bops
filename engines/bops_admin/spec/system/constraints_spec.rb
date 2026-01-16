# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constraints", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "allows adding a constraint" do
    create(:constraint, local_authority:, type: "biodiversity")

    visit "/admin/constraints"
    expect(page).to have_selector("h1", text: "Manage constraints")

    click_link("Add constraint")
    expect(page).to have_selector("h1", text: "Add a new constraint")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Type can't be blank", href: "#constraint-type-field-error")

    fill_in "Category", with: "Heritage and conservation"
    fill_in "Type", with: "Biodiversity"

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Type has already been taken", href: "#constraint-type-field-error")

    fill_in "Category", with: "Heritage and conservation"
    fill_in "Type", with: "Design"

    click_button("Submit")
    expect(page).to have_current_path("/admin/constraints")
    expect(page).to have_content("Constraint successfully created")

    within "tbody tr:nth-child(3)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")
    end
  end

  it "allows editing an constraint" do
    create(:constraint, local_authority:, type: "design")

    visit "/admin/constraints"
    expect(page).to have_selector("h1", text: "Manage constraints")

    within "tbody tr:nth-child(2)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit constraint")

    fill_in "Type", with: "Design and access"

    click_button("Submit")
    expect(page).to have_current_path("/admin/constraints")
    expect(page).to have_content("Constraint successfully updated")

    within "tbody tr:nth-child(2)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design and access")
    end
  end

  it "allows deleting a constraint" do
    create(:constraint, local_authority:, type: "design")

    visit "/admin/constraints"
    expect(page).to have_selector("h1", text: "Manage constraints")

    within "tbody tr:nth-child(2)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")

      click_link("Delete")
    end

    expect(page).to have_content("Constraint successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No constraints found")
  end

  context "when there are more than ten local constraints" do
    before do
      25.times { |n| create(:constraint, local_authority:, type: "duplicate #{n}") }
    end

    it "paginates the constraint list" do
      visit "/admin/constraints"
      expect(page).to have_selector("h1", text: "Manage constraints")
      expect(page).to have_selector("tbody tr", count: 11)

      within ".govuk-pagination" do
        expect(page).to have_selector("ul li", count: 3)
        expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
        expect(page).to have_no_link("Previous")
        expect(page).to have_link("Next", href: "/admin/constraints?page=2")
      end

      click_link("Next")
      expect(page).to have_current_path("/admin/constraints?page=2")

      within ".govuk-pagination" do
        expect(page).to have_selector("ul li", count: 3)
        expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
        expect(page).to have_link("Previous", href: "/admin/constraints?page=1")
        expect(page).to have_link("Next", href: "/admin/constraints?page=3")
      end

      click_link("Next")
      expect(page).to have_current_path("/admin/constraints?page=3")

      within ".govuk-pagination" do
        expect(page).to have_selector("ul li", count: 3)
        expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
        expect(page).to have_link("Previous", href: "/admin/constraints?page=2")
        expect(page).to have_no_link("Next")
      end
    end

    it "redirects to the first page if the page parameter overflows" do
      visit "/admin/constraints?page=2"
      expect(page).to have_selector("h1", text: "Manage constraints")
      expect(page).to have_current_path("/admin/constraints?page=2")

      visit "/admin/constraints?page=4"
      expect(page).to have_selector("h1", text: "Manage constraints")
      expect(page).to have_current_path("/admin/constraints")
    end
  end
end
