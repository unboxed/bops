# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Policy references" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  let!(:building_control) { create(:local_authority_policy_area, local_authority:, description: "Building Control") }
  let!(:environment) { create(:local_authority_policy_area, local_authority:, description: "Environment") }

  before do
    sign_in(user)
  end

  it "paginates the policy reference list" do
    25.times { create(:local_authority_policy_reference, local_authority:) }

    visit "/admin/policy/references"
    expect(page).to have_selector("h1", text: "Manage policy references")
    expect(page).to have_selector("tbody tr", count: 10)

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/policy/references?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/policy/references?page=2")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
      expect(page).to have_link("Previous", href: "/admin/policy/references?page=1")
      expect(page).to have_link("Next", href: "/admin/policy/references?page=3")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/policy/references?page=3")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
      expect(page).to have_link("Previous", href: "/admin/policy/references?page=2")
      expect(page).to have_no_link("Next")
    end
  end

  it "allows searching for a policy reference" do
    25.times { create(:local_authority_policy_reference, local_authority:) }

    policy_reference = create(
      :local_authority_policy_reference,
      local_authority:,
      code: "PP-256",
      description: "Biodiversity",
      url: "https://planx.example.com/planning-guidance",
      policy_areas: [environment]
    )

    visit "/admin/policy/references"
    expect(page).to have_selector("h1", text: "Manage policy references")

    # Find by description
    fill_in "Find policy references", with: "Biodiversity"

    click_button("Find policy references")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "PP-256")

      within "td:nth-child(2)" do
        expect(page).to have_link("Biodiversity", href: "https://planx.example.com/planning-guidance")
      end

      expect(page).to have_selector("td:nth-child(3)", text: "Environment")

      within "td:nth-child(4)" do
        expect(page).to have_link("Edit", href: "/admin/policy/references/#{policy_reference.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/policy/references/#{policy_reference.to_param}")
      end
    end

    # Find by code
    fill_in "Find policy references", with: "PP-256"

    click_button("Find policy references")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(1)", text: "PP-256")

      within "td:nth-child(2)" do
        expect(page).to have_link("Biodiversity", href: "https://planx.example.com/planning-guidance")
      end

      expect(page).to have_selector("td:nth-child(3)", text: "Environment")

      within "td:nth-child(4)" do
        expect(page).to have_link("Edit", href: "/admin/policy/references/#{policy_reference.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/policy/references/#{policy_reference.to_param}")
      end
    end
  end

  it "allows adding a policy reference" do
    create(:local_authority_policy_reference, local_authority:, code: "PP-256", description: "Biodiversity")

    visit "/admin/policy/references"
    expect(page).to have_selector("h1", text: "Manage policy references")

    click_link("Add policy reference")
    expect(page).to have_selector("h1", text: "Add a new policy reference")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Code can't be blank", href: "#policy-reference-code-field-error")
    expect(page).to have_link("Description can't be blank", href: "#policy-reference-description-field-error")

    fill_in "Code", with: "PP-256"
    fill_in "Description", with: "Biodiversity"

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Code has already been taken", href: "#policy-reference-code-field-error")
    expect(page).to have_link("Description has already been taken", href: "#policy-reference-description-field-error")

    fill_in "Code", with: "PP-999"
    fill_in "Description", with: "Design"
    check "Building Control"

    click_button("Submit")
    expect(page).to have_current_path("/admin/policy/references")
    expect(page).to have_content("Policy reference successfully created")

    within "tbody tr:nth-child(2)" do
      expect(page).to have_selector("td:nth-child(1)", text: "PP-999")
      expect(page).to have_selector("td:nth-child(2)", text: "Design")
      expect(page).to have_selector("td:nth-child(3)", text: "Building Control")
    end
  end

  it "allows editing an policy reference" do
    create(:local_authority_policy_reference, local_authority:, code: "PP-256", description: "Biodiversity")

    visit "/admin/policy/references"
    expect(page).to have_selector("h1", text: "Manage policy references")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(2)", text: "Biodiversity")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit policy reference")

    fill_in "Description", with: "Biodiversity net gain"

    click_button("Submit")
    expect(page).to have_current_path("/admin/policy/references")
    expect(page).to have_content("Policy reference successfully updated")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(2)", text: "Biodiversity net gain")
    end
  end

  it "allows deleting a policy reference" do
    create(:local_authority_policy_reference, local_authority:, code: "PP-256", description: "Biodiversity")

    visit "/admin/policy/references"
    expect(page).to have_selector("h1", text: "Manage policy references")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("td:nth-child(2)", text: "Biodiversity")

      accept_confirm do
        click_link("Delete")
      end
    end

    expect(page).to have_content("Policy reference successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No policy references found")
  end

  it "redirects to the first page if the page parameter overflows" do
    25.times { create(:local_authority_policy_reference, local_authority:) }

    visit "/admin/policy/references?page=2"
    expect(page).to have_selector("h1", text: "Manage policy references")
    expect(page).to have_current_path("/admin/policy/references?page=2")

    visit "/admin/policy/references?page=4"
    expect(page).to have_selector("h1", text: "Manage policy references")
    expect(page).to have_current_path("/admin/policy/references")
  end
end
