# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Show page", type: :system do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, :pre_application, local_authority: local_authority) }

  before do
    visit "/preapps/cases/#{planning_application.reference}"
  end

  it "I can view the show page" do
    expect(page).to have_current_path("/preapps/cases/#{planning_application.reference}")
    expect(page).to have_content("Application")
  end

  it "Shows the top level tasks" do
    expect(page).to have_link("Check and validate")
    expect(page).to have_link("Consultees")
    expect(page).to have_link("Check and assess")
  end
end
