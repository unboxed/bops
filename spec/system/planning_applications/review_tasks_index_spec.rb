# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Review Tasks Index", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create :user, :reviewer, local_authority: default_local_authority }

  context "with a reviewer" do
    before do
      sign_in reviewer
    end

    it "while awaiting determination it can navigate around review tasks" do
      visit planning_application_path(create(:planning_application, :awaiting_determination,
                                             local_authority: default_local_authority))

      click_on "Review and sign-off"

      expect(page).to have_title("Review and sign-off")

      click_on "Back"

      expect(page).to have_title("Planning Application")
    end

    it "without awaiting determination there is no navigation" do
      visit planning_application_path(create(:planning_application,
                                             :not_started,
                                             local_authority: default_local_authority))

      expect(page).to have_content("Review and sign-off")
    end
  end
end
