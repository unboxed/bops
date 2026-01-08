# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recommended application type assessment task" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: local_authority) }

  before do
    sign_in assessor
  end

  context "when application is not pre advice" do
    let!(:planning_application) do
      create(:planning_application, :awaiting_determination, local_authority: local_authority)
    end

    it "does not have a section to recommended application type" do
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      expect(page).not_to have_css("#choose-application-type")
      expect(page).not_to have_content("Choose application type")
    end
  end
end
