# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Decisions", type: :system do
  let!(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }
  let!(:decision) { create(:decision, :pa_granted) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  before do
    sign_in(user)
    visit "/"
  end

  it "allows viewing of decisions" do
    click_link "Decisions"

    expect(page).to have_selector("h1", text: "Decisions")
    expect(page).to have_link("Create decision", href: "/decisions/new")

    within "table" do
      within "thead tr" do
        expect(page).to have_selector("th:nth-child(1)", text: "Category")
        expect(page).to have_selector("th:nth-child(2)", text: "Code")
        expect(page).to have_selector("th:nth-child(3)", text: "Description")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody tr:nth-child(1)" do
        expect(page).to have_selector("td:nth-child(1)", text: "Prior Approval")
        expect(page).to have_selector("td:nth-child(2)", text: "Granted")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior approval required and approved")

        within "td:nth-child(4)" do
          expect(page).to have_link("Edit", href: "/decisions/#{decision.id}/edit")
        end
      end
    end
  end

  it "allows creation of decisions" do
    click_link "Decisions"
    expect(page).to have_selector("h1", text: "Decisions")

    click_link "Create decision"
    expect(page).to have_selector("h1", text: "Create decision")

    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "Choose a category for this decision")
    expect(page).to have_selector("[role=alert] li", text: "Choose a code for this decision")
    expect(page).to have_selector("[role=alert] li", text: "Enter a description for this decision")

    fill_in "Description", with: "Prior approval not required"
    choose "Not required"
    choose "Prior Approval"

    click_button "Save"
    expect(page).to have_content("Decision successfully created")

    within "table" do
      expect(page).to have_selector("td:nth-child(1)", text: "Prior Approval")
      expect(page).to have_selector("td:nth-child(2)", text: "Not required")
      expect(page).to have_selector("td:nth-child(3)", text: "Prior approval not required")
      expect(page).to have_selector("td:nth-child(4) a", text: "Edit")
    end
  end

  it "allows editing of decisions" do
    create(:decision, :pa_not_required)

    click_link "Decisions"
    expect(page).to have_selector("h1", text: "Decisions")

    within "table" do
      within "tbody tr:nth-child(2)" do
        expect(page).to have_selector("td:nth-child(1)", text: "Prior Approval")
        expect(page).to have_selector("td:nth-child(2)", text: "Not required")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior approval not required")
        expect(page).to have_selector("td:nth-child(4) a", text: "Edit")

        click_link "Edit"
      end
    end

    expect(page).to have_selector("h1", text: "Edit decision")

    fill_in "Description", with: "Prior approval required and refused"
    choose "Refused"

    click_button "Save"

    expect(page).to have_content("Decision successfully updated")

    within "table" do
      within "tbody tr:nth-child(2)" do
        expect(page).to have_selector("td:nth-child(1)", text: "Prior Approval")
        expect(page).to have_selector("td:nth-child(2)", text: "Refused")
        expect(page).to have_selector("td:nth-child(3)", text: "Prior approval required and refused")
        expect(page).to have_selector("td:nth-child(4) a", text: "Edit")
      end
    end
  end
end
