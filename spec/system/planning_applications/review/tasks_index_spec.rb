# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing Tasks Index" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }
  let!(:planning_application) do
    create(
      :planning_application,
      :planning_permission,
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
      visit "/planning_applications/#{planning_application.reference}"

      click_on "Review and sign-off"

      expect(page).to have_title("Review and sign-off")
      expect(page).to have_content("Assessor recommendation To grant")

      within("#constraints") do
        expect(page).to have_selector("h2", text: "Constraints (0)")
        expect(page).to have_selector("p", text: "No constraints have been added or identified")
      end

      within("#neighbours") do
        expect(page).to have_selector("h2", text: "Neighbours (0)")
        expect(page).to have_link("Show details", href: "/planning_applications/#{planning_application.reference}/consultation/neighbour_responses")
      end

      within("#consultees") do
        expect(page).to have_selector("h2", text: "Consultees (0)")
        expect(page).to have_link("Show details", href: "/planning_applications/#{planning_application.reference}/consultee/responses")
      end

      within("#documents") do
        expect(page).to have_selector("h2", text: "Documents (0)")
        expect(page).to have_link("Show details", href: "/planning_applications/#{planning_application.reference}/documents")
      end

      click_on "Back"

      expect(page).to have_title("Planning Application")
    end

    context "when application type does not support consultation" do
      let!(:planning_application) do
        create(
          :planning_application,
          :lawfulness_certificate,
          :awaiting_determination,
          local_authority: default_local_authority
        )
      end

      it "does not show consultation sections in the review task" do
        create(:recommendation, planning_application:)
        visit "/planning_applications/#{planning_application.reference}"

        click_on "Review and sign-off"

        expect(page).to have_css("#constraints")
        expect(page).not_to have_css("#neighbours")
        expect(page).not_to have_css("#consultees")
        expect(page).to have_css("#documents")
      end
    end

    it "without awaiting determination there is no navigation" do
      visit "/planning_applications/#{not_started_planning_application.id}"

      expect(page).to have_content("Review and sign-off")
    end

    it "displays chosen policy class in a list" do
      policy_classes = create_list(:policy_class, 3, planning_application:)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

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
