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
      local_authority: default_local_authority,
      description: "Test description",
      address_1: "123 Long Lane",
      town: "Big City",
      postcode: "AB34EF",
      uprn: "123456789",
      validated_at: Date.new(2022, 11, 12),
      received_at: Date.new(2022, 11, 11)
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
      within("#application_details") do
        expect(page).to have_selector("h2", text: "Application details")

        expect(page).to have_row_for("Description:", with: "Test description")
        expect(page).to have_row_for("Application type:", with: "Planning Permission - Full householder")
        expect(page).to have_row_for("Site address:", with: "123 Long Lane, Big City, AB34EF")
        expect(page).to have_row_for("Location:", with: "View site on Google Maps (opens in new tab)")
        expect(page).to have_row_for("Valid from:", with: "12 November 2022")
        expect(page).to have_row_for("Expiry date:", with: "7 January 2023")
        expect(page).to have_row_for("Consultation end:", with: "Not yet started")
        expect(page).to have_row_for("Press notice:", with: "-")
        expect(page).to have_row_for("Site notice:", with: "-")
      end

      within("#constraints") do
        expect(page).to have_selector("h2", text: "Constraints (0)")
        expect(page).to have_selector("p", text: "No constraints have been added or identified")
      end

      within("#neighbours") do
        expect(page).to have_selector("h2", text: "Neighbours (0)")
        expect(page).to have_selector("p", text: "You have not selected any neighbours")
        expect(page).to have_link("Select and add neighbours", href: "/planning_applications/#{planning_application.reference}/consultation/neighbours")
      end

      within("#consultees") do
        expect(page).to have_selector("h2", text: "Consultees (0)")
        expect(page).to have_link("Show details", href: "/planning_applications/#{planning_application.reference}/consultees")
      end

      within("#site_history") do
        expect(page).to have_selector("h2", text: "Site history (0)")
        expect(page).to have_selector("p", text: "There is no site history for this property.")
        expect(page).to have_link("Show details", href: "/planning_applications/#{planning_application.reference}/assessment/site_histories")
      end

      within("#documents") do
        expect(page).to have_selector("h2", text: "Documents (0)")
        expect(page).to have_selector("p", text: "There are no documents")
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

      it "displays chosen policy class in a list" do
        policy_class = create(:planning_application_policy_class, planning_application:)
        policy_class.current_review.complete!
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        expect(page).to have_selector("h1", text: "Review and sign-off")

        click_link "Review assessment against legislation"
        expect(page).to have_link("Review assessment of Part 1, Class #{policy_class.policy_class.section}",
          href: "/planning_applications/#{planning_application.reference}/review/policy_areas/policy_classes/#{policy_class.id}/edit")

        expect(page).to have_list_item_for(
          "Review assessment of Part 1, Class #{policy_class.policy_class.section}",
          with: "Not started"
        )
      end
    end

    it "without awaiting determination there is no navigation" do
      visit "/planning_applications/#{not_started_planning_application.id}"

      expect(page).to have_content("Review and sign-off")
    end
  end
end
