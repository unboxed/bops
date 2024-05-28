# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Policy areas", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "paginates the policy area list" do
    25.times { create(:local_authority_policy_area, local_authority:) }

    visit "/admin/policy/areas"
    expect(page).to have_selector("h1", text: "Manage policy areas")
    expect(page).to have_selector("tbody tr", count: 10)

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/policy/areas?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/policy/areas?page=2")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
      expect(page).to have_link("Previous", href: "/admin/policy/areas?page=1")
      expect(page).to have_link("Next", href: "/admin/policy/areas?page=3")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/policy/areas?page=3")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
      expect(page).to have_link("Previous", href: "/admin/policy/areas?page=2")
      expect(page).to have_no_link("Next")
    end
  end

  it "allows searching for a policy area" do
    25.times { create(:local_authority_policy_area, local_authority:) }
    policy_area = create(:local_authority_policy_area, local_authority:, description: "Design")

    visit "/admin/policy/areas"
    expect(page).to have_selector("h1", text: "Manage policy areas")

    fill_in "Find policy areas", with: "Design"

    click_button("Find policy areas")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")

      within "td:nth-child(2)" do
        expect(page).to have_link("Edit", href: "/admin/policy/areas/#{policy_area.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/policy/areas/#{policy_area.to_param}")
      end
    end
  end

  it "allows adding a policy area" do
    create(:local_authority_policy_area, local_authority:, description: "Biodiversity")

    visit "/admin/policy/areas"
    expect(page).to have_selector("h1", text: "Manage policy areas")

    click_link("Add policy area")
    expect(page).to have_selector("h1", text: "Add a new policy area")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Description can't be blank", href: "#policy-area-description-field-error")

    fill_in "Description", with: "Biodiversity"

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Description has already been taken", href: "#policy-area-description-field-error")

    fill_in "Description", with: "Design"

    click_button("Submit")
    expect(page).to have_current_path("/admin/policy/areas")
    expect(page).to have_content("Policy area successfully created")

    within "tbody tr:nth-child(2)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")
    end
  end

  it "allows editing an policy area" do
    create(:local_authority_policy_area, local_authority:, description: "Design")

    visit "/admin/policy/areas"
    expect(page).to have_selector("h1", text: "Manage policy areas")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit policy area")

    fill_in "Description", with: "Design and access"

    click_button("Submit")
    expect(page).to have_current_path("/admin/policy/areas")
    expect(page).to have_content("Policy area successfully updated")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design and access")
    end
  end

  it "allows deleting a policy area" do
    create(:local_authority_policy_area, local_authority:, description: "Design")

    visit "/admin/policy/areas"
    expect(page).to have_selector("h1", text: "Manage policy areas")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "Design")

      accept_confirm do
        click_link("Delete")
      end
    end

    expect(page).to have_content("Policy area successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No policy areas found")
  end

  it "redirects to the first page if the page parameter overflows" do
    25.times { create(:local_authority_policy_area, local_authority:) }

    visit "/admin/policy/areas?page=2"
    expect(page).to have_selector("h1", text: "Manage policy areas")
    expect(page).to have_current_path("/admin/policy/areas?page=2")

    visit "/admin/policy/areas?page=4"
    expect(page).to have_selector("h1", text: "Manage policy areas")
    expect(page).to have_current_path("/admin/policy/areas")
  end
end
