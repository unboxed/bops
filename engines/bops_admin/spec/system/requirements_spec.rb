# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requirement" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  let!(:building_control) { create(:local_authority_policy_area, local_authority:, description: "Building Control") }
  let!(:environment) { create(:local_authority_policy_area, local_authority:, description: "Environment") }

  before do
    sign_in(user)
  end

  it "paginates the requirement list" do
    25.times { create(:local_authority_requirement, local_authority:) }

    visit "/admin/requirements"
    expect(page).to have_selector("h1", text: "Manage requirements")
    expect(page).to have_selector("tbody tr", count: 10)

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/requirements?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/requirements?page=2")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
      expect(page).to have_link("Previous", href: "/admin/requirements?page=1")
      expect(page).to have_link("Next", href: "/admin/requirements?page=3")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/requirements?page=3")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
      expect(page).to have_link("Previous", href: "/admin/requirements?page=2")
      expect(page).to have_no_link("Next")
    end
  end

  it "allows searching for a requirement" do
    25.times { create(:local_authority_requirement, local_authority:) }

    requirement = create(
      :local_authority_requirement,
      local_authority:,
      category: "drawings",
      description: "Floor plans - existing",
      guidelines: "Drawings to the scale of 1:100",
      url: "https://planx.example.com/planning-guidance"
    )

    visit "/admin/requirements"
    expect(page).to have_selector("h1", text: "Manage requirements")

    fill_in "Find requirement", with: "Floor plans - existing"

    click_button("Find requirement")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      within "td:nth-child(1)" do
        expect(page).to have_text("Drawings")
      end

      within "td:nth-child(2)" do
        expect(page).to have_link("Floor plans - existing", href: "https://planx.example.com/planning-guidance")
      end

      within "td:nth-child(3)" do
        expect(page).to have_link("Edit", href: "/admin/requirements/#{requirement.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/requirements/#{requirement.to_param}")
      end
    end
  end

  it "allows adding a requirement" do
    create(:local_authority_requirement, local_authority:, description: "Floor plans - existing")

    visit "/admin/requirements"
    expect(page).to have_selector("h1", text: "Manage requirements")

    click_link("Add requirement")
    expect(page).to have_selector("h1", text: "Add a new requirement")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Description can't be blank", href: "#requirement-description-field-error")

    fill_in "Description", with: "Floor plans - existing"

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Category can't be blank", href: "#requirement-category-field-error")
    expect(page).to have_link("Description has already been taken", href: "#requirement-description-field-error")

    choose "Drawings"
    fill_in "Description", with: "Floor plans - proposed"

    click_button("Submit")
    expect(page).to have_current_path("/admin/requirements")
    expect(page).to have_content("Requirement successfully created")

    within "tbody tr:nth-child(2)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Drawings")
      expect(page).to have_selector("td:nth-child(2)", text: "Floor plans - proposed")
    end
  end

  it "allows editing an requirement" do
    create(:local_authority_requirement, local_authority:, category: "drawings", description: "Floor plans - existing")

    visit "/admin/requirements"
    expect(page).to have_selector("h1", text: "Manage requirements")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Drawings")
      expect(page).to have_selector("td:nth-child(2)", text: "Floor plans - existing")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit requirement")

    fill_in "Description", with: "Floor plans"

    click_button("Submit")
    expect(page).to have_current_path("/admin/requirements")
    expect(page).to have_content("Requirement successfully updated")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Drawings")
      expect(page).to have_selector("td:nth-child(2)", text: "Floor plans")
    end
  end

  it "allows deleting a requirement", :capybara do
    create(:local_authority_requirement, local_authority:, description: "Floor plans - existing")

    visit "/admin/requirements"
    expect(page).to have_selector("h1", text: "Manage requirements")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(2)", text: "Floor plans - existing")

      accept_confirm do
        click_link("Delete")
      end
    end

    expect(page).to have_content("Requirement successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No requirements found")
  end

  it "redirects to the first page if the page parameter overflows" do
    25.times { create(:local_authority_requirement, local_authority:) }

    visit "/admin/requirements?page=2"
    expect(page).to have_selector("h1", text: "Manage requirements")
    expect(page).to have_current_path("/admin/requirements?page=2")

    visit "/admin/requirements?page=4"
    expect(page).to have_selector("h1", text: "Manage requirements")
    expect(page).to have_current_path("/admin/requirements")
  end
end
