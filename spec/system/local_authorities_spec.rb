# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessing correct local authority", type: :system do
  let!(:lambeth) { create(:local_authority, :lambeth) }
  let!(:southwark) { create(:local_authority, :southwark) }

  context "Lambeth council" do
    before do
      @previous_host = Capybara.app_host
      Capybara.app_host = "http://lambeth.example.com"
    end

    after do
      Capybara.app_host = "http://#{@previous_host}"
    end

    it "visit namespaced path" do
      visit root_path

      expect(page.body).to have_content("Lambeth Council")
      expect(page.body).not_to have_content("Southwark Council")
    end
  end

  context "Non existent council" do
    before do
      @previous_host = Capybara.app_host
      Capybara.app_host = "http://biscuits.example.com"
    end

    after do
      Capybara.app_host = "http://#{@previous_host}"
    end

    it "visit non existing path" do
      visit root_path
      expect(page).to have_content("No Local Authority Found")
    end
  end
end
