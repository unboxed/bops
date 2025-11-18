# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check site history", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the form" do
    within ".bops-sidebar" do
      click_link "Check site history"
    end
    click_button "Save"

    expect(planning_application.reload.site_history_checked).to be true
  end
end
