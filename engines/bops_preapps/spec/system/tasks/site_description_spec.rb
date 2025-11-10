# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site description task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Site description"
    end
    fill_in "task[entry]", with: "Words words words"

    click_button "Save"

    expect(planning_application.reload.assessment_details.where(category: :site_description).last.entry).to eq("Words words words")
  end
end
