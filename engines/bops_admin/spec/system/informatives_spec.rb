# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Informatives" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
  end

  it "paginates the informative list" do
    25.times { create(:local_authority_informative, local_authority:) }

    visit "/admin/informatives"
    expect(page).to have_selector("h1", text: "Manage informatives")
    expect(page).to have_selector("tbody tr", count: 10)

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "1")
      expect(page).to have_no_link("Previous")
      expect(page).to have_link("Next", href: "/admin/informatives?page=2")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/informatives?page=2")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "2")
      expect(page).to have_link("Previous", href: "/admin/informatives?page=1")
      expect(page).to have_link("Next", href: "/admin/informatives?page=3")
    end

    click_link("Next")
    expect(page).to have_current_path("/admin/informatives?page=3")

    within ".govuk-pagination" do
      expect(page).to have_selector("ul li", count: 3)
      expect(page).to have_selector(".govuk-pagination__item--current", text: "3")
      expect(page).to have_link("Previous", href: "/admin/informatives?page=2")
      expect(page).to have_no_link("Next")
    end
  end

  it "allows searching for an informative" do
    25.times { create(:local_authority_informative, local_authority:) }
    informative = create(:local_authority_informative, local_authority:, title: "Section 106", text: "Section 106 needs doing")

    visit "/admin/informatives"
    expect(page).to have_selector("h1", text: "Manage informatives")

    fill_in "Find informative", with: "Section 106"

    click_button("Find informative")
    expect(page).to have_selector("tbody tr", count: 1)

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Section 106")
      expect(page).to have_selector("td:nth-child(2)", text: "Section 106 needs doing")

      within "td:nth-child(3)" do
        expect(page).to have_link("Edit", href: "/admin/informatives/#{informative.to_param}/edit")
        expect(page).to have_link("Delete", href: "/admin/informatives/#{informative.to_param}")
      end
    end
  end

  it "allows adding an informative" do
    visit "/admin/informatives"
    expect(page).to have_selector("h1", text: "Manage informatives")

    click_link("Add informative")
    expect(page).to have_selector("h1", text: "Add a new informative")

    click_button("Submit")
    expect(page).to have_selector("h2", text: "There is a problem")
    expect(page).to have_link("Title can't be blank", href: "#informative-title-field-error")
    expect(page).to have_link("Text can't be blank", href: "#informative-text-field-error")

    fill_in "Title", with: "Section 106"
    fill_in "Text", with: "Section 106 needs doing"

    click_button("Submit")
    expect(page).to have_current_path("/admin/informatives")
    expect(page).to have_content("Informative successfully created")
  end

  it "allows editing an informative" do
    create(:local_authority_informative, local_authority:, title: "Section 106", text: "Section 106 needs doing")

    visit "/admin/informatives"
    expect(page).to have_selector("h1", text: "Manage informatives")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Section 106")
      expect(page).to have_selector("td:nth-child(2)", text: "Section 106 needs doing")

      click_link("Edit")
    end

    expect(page).to have_selector("h1", text: "Edit informative")

    fill_in "Text", with: "Section 106 really needs doing"

    click_button("Submit")
    expect(page).to have_current_path("/admin/informatives")
    expect(page).to have_content("Informative successfully updated")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Section 106")
      expect(page).to have_selector("td:nth-child(2)", text: "Section 106 really needs doing")
    end
  end

  it "allows deleting an informative" do
    create(:local_authority_informative, local_authority:, title: "Section 106", text: "Section 106 needs doing")

    visit "/admin/informatives"
    expect(page).to have_selector("h1", text: "Manage informatives")

    within "tbody tr:nth-child(1)" do
      expect(page).to have_selector("th:nth-child(1)", text: "Section 106")

      accept_confirm do
        click_link("Delete")
      end
    end

    expect(page).to have_content("Informative successfully deleted")
    expect(page).to have_selector("tbody tr:nth-child(1)", text: "No informatives found")
  end

  it "redirects to the first page if the page parameter overflows" do
    25.times { create(:local_authority_informative, local_authority:) }

    visit "/admin/informatives?page=2"
    expect(page).to have_selector("h1", text: "Manage informatives")
    expect(page).to have_current_path("/admin/informatives?page=2")

    visit "/admin/informatives?page=4"
    expect(page).to have_selector("h1", text: "Manage informatives")
    expect(page).to have_current_path("/admin/informatives")
  end
end
