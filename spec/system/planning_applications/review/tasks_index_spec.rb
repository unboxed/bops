# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing Tasks Index" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }
  let!(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      local_authority: default_local_authority
    )
  end

  let!(:not_started_planning_application) do
    create(
      :planning_application,
      :not_started,
      local_authority: default_local_authority
    )
  end

  context "with a reviewer" do
    before do
      create(:recommendation, planning_application:)
      sign_in reviewer
    end

    it "while awaiting determination it can navigate around review tasks" do
      create(:recommendation, planning_application:)
      visit "/planning_applications/#{planning_application.id}"

      click_on "Review and sign-off"

      expect(page).to have_title("Review and sign-off")
      expect(page).to have_content("Assessor recommendation To grant")

      click_on "Back"

      expect(page).to have_title("Planning Application")
    end

    it "without awaiting determination there is no navigation" do
      visit "/planning_applications/#{not_started_planning_application.id}"

      expect(page).to have_content("Review and sign-off")
    end

    it "displays chosen policy class in a list" do
      policy_classes = create_list(:policy_class, 3, planning_application:)
      visit "/planning_applications/#{planning_application.id}/review/tasks"

      expect(page).to have_selector("h1", text: "Review and sign-off")
      policy_classes.each do |policy_class|
        expect(page).to have_link("Review assessment of Part 1, Class #{policy_class.section}",
          href: edit_planning_application_review_policy_class_path(planning_application, policy_class))

        expect(page).to have_list_item_for(
          "Review assessment of Part 1, Class #{policy_class.section}",
          with: "Not started"
        )
      end
    end
  end
end
