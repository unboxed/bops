# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add interested parties", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:case_record) { build(:case_record, local_authority:) }
  let(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in user
    visit "/enforcements/#{enforcement.reference}/investigate-and-decide/update-site-and-owner-details/add-interested-parties"
  end

  context "when there is an interested party" do
    let(:interested_party) { create(:enforcement_interested_party, enforcement:) }

    before do
      enforcement.interested_parties << interested_party # not sure why the relationship doesn't just get added above?
      visit "/enforcements/#{enforcement.reference}/investigate-and-decide/update-site-and-owner-details/add-interested-parties"
    end

    it "lists the interested party" do
      within ".govuk-table" do
        expect(page).to have_content(interested_party.name)
      end
    end

    it "closes the form by default" do
      expect(page).to have_xpath(".//details")
      expect(page).not_to have_xpath(".//details[@open]")
    end

    it "can edit the party" do
      click_link "Edit"
      fill_in "Name", with: "Bob Dylan"
      click_on "Save"

      within ".govuk-table" do
        expect(page).to have_content("Bob Dylan")
      end
    end

    it "can delete the party" do
      expect {
        click_on "Remove"
      }.to change(enforcement.interested_parties, :count).from(1).to(0)
    end
  end

  context "when there is no interested party" do
    it "opens the form by default" do
      expect(page).to have_xpath(".//details[@open]")
    end

    it "has an empty table" do
      expect(page).to have_selector(".govuk-table")
      expect(page).not_to have_selector(".govuk-table > *")
    end

    it "can add a party" do
      fill_in "Name", with: "Bob Dylan"
      fill_in "Address line 1", with: "60-62 Commercial Street"
      fill_in "Town", with: "London"
      fill_in "Postcode", with: "E1 6LT"
      choose "Owner"
      click_button "Add"

      expect(page).to have_content("Successfully added")

      within ".govuk-table" do
        expect(page).to have_content("Bob Dylan")
      end
    end
  end
end
