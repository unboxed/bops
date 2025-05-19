# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Policy guidance" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  let!(:building_control) { create(:local_authority_policy_area, local_authority:, description: "Building Control") }
  let!(:environment) { create(:local_authority_policy_area, local_authority:, description: "Environment") }

  before do
    sign_in(user)
  end

  it "paginates the policy guidance list" do
    25.times { create(:local_authority_policy_guidance, local_authority:) }

    visit "/admin/policy/guidance"
    expect(page).to have_selector("h1", text: "Manage policy guidance")
    expect(page).to have_selector("tbody tr", count: 10)

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/policy/guidance?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/policy/guidance?page=2")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
      expect(page).to have_link("Previous", href: "/admin/policy/guidance?page=1")
      expect(page).to have_link("Next", href: "/admin/policy/guidance?page=3")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/policy/guidance?page=3")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
      expect(page).to have_link("Previous", href: "/admin/policy/guidance?page=2")
      expect(page).to have_no_link("Next")
    end
  end

  it "allows searching for a policy guidance" do
    25.times { create(:local_authority_policy_guidance, local_authority:) }

    policy_guidance = create(
      :local_authority_policy_guidance,
      local_authority:,
      description: "Biodiversity",
      url: "https://planx.bops.services/planning-guidance"
    )

    visit "/admin/policy/guidance"
    expect(page).to have_selector("h1", text: "Manage policy guidance")

    fill_in "Find policy guidance", with: "Biodiversity"

    click_button("Find policy guidance")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      within "td:nth-child(1)" do
        expect(page).to have_link("Biodiversity", href: "https://planx.bops.services/planning-guidance")
      end

      within "td:nth-child(2)" do
        expect(page).to have_link("Edit", href: "/admin/policy/guidance/#{policy_guidance.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/policy/guidance/#{policy_guidance.to_param}")
      end
    end
  end

  it "allows adding a policy guidance" do
    create(:local_authority_policy_guidance, local_authority:, description: "Biodiversity")

    visit "/admin/policy/guidance"
    expect(page).to have_selector("h1", text: "Manage policy guidance")

    click_link("Add policy guidance")
    expect(page).to have_selector("h1", text: "Add a new policy guidance")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Description can't be blank", href: "#policy-guidance-description-field-error")

    fill_in "Description", with: "Biodiversity"

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Description has already been taken", href: "#policy-guidance-description-field-error")

    fill_in "Description", with: "Design"

    click_button("Submit")
    expect(page).to have_current_path("/admin/policy/guidance")
    expect(page).to have_content("Policy guidance successfully created")

    within "tbody tr:nth-child(2)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")
    end
  end

  it "allows editing an policy guidance" do
    create(:local_authority_policy_guidance, local_authority:, description: "Biodiversity")

    visit "/admin/policy/guidance"
    expect(page).to have_selector("h1", text: "Manage policy guidance")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Biodiversity")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit policy guidance")

    fill_in "Description", with: "Biodiversity net gain"

    click_button("Submit")
    expect(page).to have_current_path("/admin/policy/guidance")
    expect(page).to have_content("Policy guidance successfully updated")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Biodiversity net gain")
    end
  end

  it "allows deleting a policy guidance", :capybara do
    create(:local_authority_policy_guidance, local_authority:, description: "Biodiversity")

    visit "/admin/policy/guidance"
    expect(page).to have_selector("h1", text: "Manage policy guidance")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Biodiversity")

      accept_confirm do
        click_link("Delete")
      end
    end

    expect(page).to have_content("Policy guidance successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No policy guidance found")
  end

  it "redirects to the first page if the page parameter overflows" do
    25.times { create(:local_authority_policy_guidance, local_authority:) }

    visit "/admin/policy/guidance?page=2"
    expect(page).to have_selector("h1", text: "Manage policy guidance")
    expect(page).to have_current_path("/admin/policy/guidance?page=2")

    visit "/admin/policy/guidance?page=4"
    expect(page).to have_selector("h1", text: "Manage policy guidance")
    expect(page).to have_current_path("/admin/policy/guidance")
  end
end
