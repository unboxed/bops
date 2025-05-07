# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review Tasks" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }
  let(:reference) { planning_application.reference }

  before do
    sign_in reviewer
  end

  context "when the application has a recommendation" do
    let(:planning_application) do
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

    before do
      create(:recommendation, planning_application:)
    end

    it "has a set of review tasks" do
      visit "/planning_applications/#{reference}"
      expect(page).to have_selector("h1", text: "Application")
      expect(page).to have_link("Review and sign-off", href: "/planning_applications/#{reference}/review/tasks")

      click_link "Review and sign-off"
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
        expect(page).to have_link("Select and add neighbours", href: "/planning_applications/#{reference}/consultation/neighbours")
      end

      within("#consultees") do
        expect(page).to have_selector("h2", text: "Consultees (0)")
        expect(page).to have_link("Show details", href: "/planning_applications/#{reference}/consultees")
      end

      within("#site_history") do
        expect(page).to have_selector("h2", text: "Site history (0)")
        expect(page).to have_selector("p", text: "There is no site history for this property.")
        expect(page).to have_link("Show details", href: "/planning_applications/#{reference}/assessment/site_histories")
      end

      within("#documents") do
        expect(page).to have_selector("h2", text: "Documents (0)")
        expect(page).to have_selector("p", text: "There are no documents")
        expect(page).to have_link("Show details", href: "/planning_applications/#{reference}/documents")
      end

      click_on "Back"
      expect(page).to have_title("Planning Application")
      expect(page).to have_selector("h1", text: "Application")
    end
  end

  context "when the application has a policy class" do
    let(:planning_application) do
      create(
        :planning_application,
        :lawfulness_certificate,
        :awaiting_determination,
        local_authority: default_local_authority
      )
    end

    let(:policy_class) { create(:planning_application_policy_class, planning_application:) }
    let(:current_review) { policy_class.current_review }
    let(:section) { policy_class.policy_class.section }

    before do
      current_review.complete!
    end

    it "displays the policy class in a list" do
      visit "/planning_applications/#{reference}/review/tasks"
      expect(page).to have_selector("h1", text: "Review and sign-off")

      click_link "Review assessment against legislation"

      expect(page).to have_link("Review assessment of Part 1, Class #{section}",
        href: "/planning_applications/#{reference}/review/policy_areas/policy_classes/#{policy_class.id}/edit")

      expect(page).to have_list_item_for("Review assessment of Part 1, Class #{section}",
        with: "Not started")
    end
  end

  context "when the application does not support consultation" do
    let(:planning_application) do
      create(
        :planning_application,
        :lawfulness_certificate,
        :awaiting_determination,
        local_authority: default_local_authority
      )
    end

    before do
      create(:recommendation, planning_application:)
    end

    it "does not show consultation sections in the review task" do
      visit "/planning_applications/#{reference}"
      expect(page).to have_selector("h1", text: "Application")

      click_link "Review and sign-off"
      expect(page).to have_selector("h1", text: "Review and sign-off")

      expect(page).to have_css("#constraints")
      expect(page).to have_css("#documents")

      expect(page).not_to have_css("#consultees")
      expect(page).not_to have_css("#neighbours")
    end
  end

  context "when the application is not started" do
    let(:planning_application) do
      create(
        :planning_application,
        :planning_permission,
        :not_started,
        local_authority: default_local_authority
      )
    end

    it "redirects back to the application page" do
      visit "/planning_applications/#{reference}/review/tasks"

      expect(page).to have_current_path("/planning_applications/#{reference}")
      expect(page).to have_selector("h1", text: "Application")
    end
  end

  context "when the application is a pre-application report" do
    let(:planning_application) do
      create(
        :planning_application,
        :pre_application,
        :awaiting_determination,
        :with_preapp_assessment,
        local_authority: default_local_authority
      )
    end

    before do
      create(:recommendation, planning_application:)
    end

    it "redirects back to the report page" do
      visit "/planning_applications/#{reference}/review/tasks"

      expect(page).to have_current_path("/reports/planning_applications/#{reference}")
      expect(page).to have_selector("h1", text: "Pre-application report")
    end
  end
end
