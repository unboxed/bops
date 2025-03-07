# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "Legislation", type: :system do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }
  let!(:legislation) { create(:legislation, title: "Town and Country Planning Act 1990, Section 192") }

  before do
    sign_in(user)
    visit "/"
  end

  it "allows creating the new legislation" do
    click_link "Legislation"
    expect(page).to have_selector("h1", text: "Legislation")

    within(".govuk-table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Title")
        expect(page).to have_selector("th:nth-child(2)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Town and Country Planning Act 1990, Section 192")
          within "td:nth-child(2)" do
            expect(page).to have_link(
              "Edit",
              href: "/legislation/#{legislation.id}/edit"
            )
          end
        end
      end
    end

    click_link "Create new legislation"
    fill_in "Link", with: "Not a link"
    click_button "Save"

    expect(page).to have_selector("[role=alert] li", text: "Enter a title for the legislation")
    expect(page).to have_selector("[role=alert] li", text: "Enter a valid url for the legislation")

    fill_in "Title", with: "The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 1, Class A"
    fill_in "Description", with: "A description about the legislation"
    fill_in "Link", with: "https://www.legislation.gov.uk/uksi/2015/596/schedule/2"
    click_button "Save"

    expect(page).to have_content("Legislation successfully created")

    within(".govuk-table tbody") do
      expect(page).to have_selector("td:nth-child(1)", text: "Town and Country Planning Act 1990, Section 192")
      expect(page).to have_selector("td:nth-child(1)", text: "The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 1, Class A")
    end
  end

  it "allows editing the legislation" do
    visit "/legislation/#{legislation.id}/edit"
    expect(page).to have_selector("h1", text: "Edit legislation")
    expect(page).to have_link("Back", href: "/legislation")
    # Legislation title is readonly
    expect(page).to have_selector("#legislation-title-field[readonly]")

    fill_in "Description", with: "A description about the legislation"
    fill_in "Link", with: "https://www.legislation.gov.uk/ukpga/1990/8/section/192"
    click_button "Save"

    expect(page).to have_content("Legislation successfully updated")
    click_link "Edit"

    expect(find_field("Description").value).to eq("A description about the legislation")
    expect(find_field("Link").value).to eq("https://www.legislation.gov.uk/ukpga/1990/8/section/192")
  end

  it "allows deleting the legislation", :capybara do
    visit "/legislation/#{legislation.id}/edit"
    accept_confirm(text: "Are you sure?") do
      click_link("Remove")
    end

    expect(page).to have_content("Legislation successfully removed")
    expect(page).not_to have_content("Town and Country Planning Act 1990, Section 192")
  end

  it "allows viewing the associated application types" do
    application_type = create(:application_type_config, :ldc_proposed, legislation:)

    visit "/legislation/#{legislation.id}/edit"
    expect(page).to have_selector("h2", text: "Application types with this legislation")
    expect(page).not_to have_link("Remove")

    within("table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Suffix")
        expect(page).to have_selector("th:nth-child(2)", text: "Name")
        expect(page).to have_selector("th:nth-child(3)", text: "Status")
        expect(page).to have_selector("th:nth-child(4)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "LDCP")
          expect(page).to have_selector("td:nth-child(2)", text: "Lawful Development Certificate - Proposed use")
          expect(page).to have_selector("td:nth-child(3) .govuk-tag--green", text: "Active")

          within "td:nth-child(4)" do
            expect(page).to have_link(
              "View and/or edit",
              href: "/application_types/#{application_type.id}"
            )
          end
        end
      end
    end
  end
end
