# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Categories", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "paginates the category list" do
    25.times { create(:local_authority_category, local_authority:) }

    visit "/admin/categories"
    expect(page).to have_selector("h1", text: "Manage categories")
    expect(page).to have_selector("tbody tr", count: 10)

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/categories?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/categories?page=2")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
      expect(page).to have_link("Previous", href: "/admin/categories?page=1")
      expect(page).to have_link("Next", href: "/admin/categories?page=3")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/categories?page=3")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
      expect(page).to have_link("Previous", href: "/admin/categories?page=2")
      expect(page).to have_no_link("Next")
    end
  end

  it "allows searching for a category" do
    25.times { create(:local_authority_category, local_authority:) }
    category = create(:local_authority_category, local_authority:, description: "Design")

    visit "/admin/categories"
    expect(page).to have_selector("h1", text: "Manage categories")

    fill_in "Find categories", with: "Design"

    click_button("Find categories")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")

      within "td:nth-child(2)" do
        expect(page).to have_link("Edit", href: "/admin/categories/#{category.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/categories/#{category.to_param}")
      end
    end
  end

  it "allows adding a category" do
    create(:local_authority_category, local_authority:, description: "Biodiversity")

    visit "/admin/categories"
    expect(page).to have_selector("h1", text: "Manage categories")

    click_link("Add category")
    expect(page).to have_selector("h1", text: "Add a new category")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Description can't be blank", href: "#category-description-field-error")

    fill_in "Description", with: "Biodiversity"

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Description has already been taken", href: "#category-description-field-error")

    fill_in "Description", with: "Design"

    click_button("Submit")
    expect(page).to have_current_path("/admin/categories")
    expect(page).to have_content("Category successfully created")

    within "tbody tr:nth-child(2)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")
    end
  end

  it "allows editing an category" do
    create(:local_authority_category, local_authority:, description: "Design")

    visit "/admin/categories"
    expect(page).to have_selector("h1", text: "Manage categories")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit category")

    fill_in "Description", with: "Design and access"

    click_button("Submit")
    expect(page).to have_current_path("/admin/categories")
    expect(page).to have_content("Category successfully updated")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design and access")
    end
  end

  it "allows deleting a category" do
    create(:local_authority_category, local_authority:, description: "Design")

    visit "/admin/categories"
    expect(page).to have_selector("h1", text: "Manage categories")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")

      accept_confirm do
        click_link("Delete")
      end
    end

    expect(page).to have_content("Category successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No categories found")
  end

  it "redirects to the first page if the page parameter overflows" do
    25.times { create(:local_authority_category, local_authority:) }

    visit "/admin/categories?page=2"
    expect(page).to have_selector("h1", text: "Manage categories")
    expect(page).to have_current_path("/admin/categories?page=2")

    visit "/admin/categories?page=4"
    expect(page).to have_selector("h1", text: "Manage categories")
    expect(page).to have_current_path("/admin/categories")
  end
end
