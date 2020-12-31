# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessing correct local authority", type: :system do
  let!(:lambeth) { create :local_authority, name: "Lambeth Council", subdomain: "lambeth" }
  let!(:southwark) { create :local_authority, name: "Southwark Council", subdomain: "southwark" }

  context "Lambeth council" do
    # rubocop:disable RSpec/InstanceVariable
    before do
      @previous_host = Capybara.app_host
      host! "http://lambeth.example.com"
    end

    after do
      host! "http://#{@previous_host}"
    end
    # rubocop:enable RSpec/InstanceVariable

    it "visit namespaced path" do
      visit root_path

      expect(page.body).to have_content("Lambeth Council")
      expect(page.body).not_to have_content("Southwark Council")
    end
  end

  context "Non existent council" do
    # rubocop:disable RSpec/InstanceVariable
    before do
      @previous_host = Capybara.app_host
      host! "http://biscuits.example.com"
    end

    after do
      host! "http://#{@previous_host}"
    end
    # rubocop:enable RSpec/InstanceVariable

    it "visit non existing path" do
      visit root_path
      expect(page).to have_content("No Local Authority Found")
    end
  end
end
