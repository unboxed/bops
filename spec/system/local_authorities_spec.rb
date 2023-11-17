# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessing correct local authority" do
  let!(:lambeth) { create(:local_authority, :lambeth) }
  let!(:southwark) { create(:local_authority, :southwark) }

  context "with Lambeth council" do
    before do
      @previous_host = Capybara.app_host
      Capybara.app_host = "http://#{lambeth.subdomain}.example.com"
    end

    after do
      Capybara.app_host = "http://#{@previous_host}"
    end

    it "visit namespaced path" do
      visit "/"

      expect(page).to have_content("Lambeth Back-office Planning System")
      expect(page).not_to have_content("Southwark Back-office Planning System")
    end
  end

  context "with non existent council" do
    before do
      @previous_host = Capybara.app_host
      Capybara.app_host = "http://biscuits.example.com"
    end

    after do
      Capybara.app_host = "http://#{@previous_host}"
    end

    it "visit non existing path" do
      visit "/"
      expect(page).to have_content("No Local Authority Found")
    end
  end
end
