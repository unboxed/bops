# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultees" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "paginates the consultee list" do
    25.times { create(:contact, local_authority:) }

    visit "/admin/consultees"
    expect(page).to have_selector("h1", text: "Manage consultees")
    expect(page).to have_selector("tbody tr", count: 10)

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/consultees?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/consultees?page=2")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
      expect(page).to have_link("Previous", href: "/admin/consultees?page=1")
      expect(page).to have_link("Next", href: "/admin/consultees?page=3")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/consultees?page=3")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
      expect(page).to have_link("Previous", href: "/admin/consultees?page=2")
      expect(page).to have_no_link("Next")
    end
  end

  it "allows searching for a consultee" do
    25.times { create(:contact, local_authority:) }
    consultee = create(:contact, :external, local_authority:, name: "Planning Officer", role: nil, organisation: "London Fire Brigade")

    visit "/admin/consultees"
    expect(page).to have_selector("h1", text: "Manage consultees")

    fill_in "Find consultees", with: "London Fire Brigade"

    click_button("Find consultees")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Planning Officer")
      expect(page).to have_selector("td:nth-child(2)", text: "–")
      expect(page).to have_selector("td:nth-child(3)", text: "London Fire Brigade")
      expect(page).to have_selector("td:nth-child(4)", text: "External")

      within "td:nth-child(5)" do
        expect(page).to have_link("Edit", href: "/admin/consultees/#{consultee.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/consultees/#{consultee.to_param}")
      end
    end
  end

  it "allows adding a consultee" do
    visit "/admin/consultees"
    expect(page).to have_selector("h1", text: "Manage consultees")

    click_link("Add consultee")
    expect(page).to have_selector("h1", text: "Add a new consultee")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Name can't be blank", href: "#consultee-name-field-error")
    expect(page).to have_link("Origin can't be blank", href: "#consultee-origin-field-error")
    expect(page).to have_link("Email address can't be blank", href: "#consultee-email-address-field-error")

    fill_in "Name", with: "Planning Officer"
    fill_in "Organisation", with: "London Fire Brigade"
    fill_in "Email address", with: "planning"
    choose "External"

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Email address is invalid", href: "#consultee-email-address-field-error")

    fill_in "Email address", with: "planning@london-fire.gov.uk"

    click_button("Submit")
    expect(page).to have_current_path("/admin/consultees")
    expect(page).to have_content("Consultee successfully created")
  end

  it "allows editing a consultee" do
    create(:contact, :internal, local_authority:, name: "Planning Officer", role: nil, organisation: "London Fire Brigade")

    visit "/admin/consultees"
    expect(page).to have_selector("h1", text: "Manage consultees")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Planning Officer")
      expect(page).to have_selector("td:nth-child(2)", text: "–")
      expect(page).to have_selector("td:nth-child(3)", text: "London Fire Brigade")
      expect(page).to have_selector("td:nth-child(4)", text: "Internal")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit consultee")

    choose "External"

    click_button("Submit")
    expect(page).to have_current_path("/admin/consultees")
    expect(page).to have_content("Consultee successfully updated")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Planning Officer")
      expect(page).to have_selector("td:nth-child(2)", text: "–")
      expect(page).to have_selector("td:nth-child(3)", text: "London Fire Brigade")
      expect(page).to have_selector("td:nth-child(4)", text: "External")
    end
  end

  it "allows deleting a consultee" do
    create(:contact, local_authority:, name: "Chris Wood")

    visit "/admin/consultees"
    expect(page).to have_selector("h1", text: "Manage consultees")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Chris Wood")

      accept_confirm do
        click_link("Delete")
      end
    end

    expect(page).to have_content("Consultee successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No consultees found")
  end

  it "redirects to the first page if the page parameter overflows" do
    25.times { create(:contact, local_authority:) }

    visit "/admin/consultees?page=4"
    expect(page).to have_selector("h1", text: "Manage consultees")
    expect(page).to have_current_path("/admin/consultees")
  end
end
