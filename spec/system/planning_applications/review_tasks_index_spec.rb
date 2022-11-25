# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Review Tasks Index", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create :user, :reviewer, local_authority: default_local_authority }
  let!(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      local_authority: default_local_authority
    )
  end

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

    it "displays chosen policy class in a list" do
      policy_classes =  create_list(:policy_class, 3, planning_application: planning_application)
      visit(planning_application_review_tasks_path(planning_application))

      expect(page).to have_selector("h1", text: "Review and sign-off")
      policy_classes.each do |policy_class|
        expect(page).to have_link("Review assessment of Part 1, Class #{policy_class.section}",
                                  href: edit_planning_application_review_policy_class_path(planning_application, policy_class))
        expect(list_item("Review assessment of Part 1, Class #{policy_class.section}")).to have_content("Not checked yet")
      end
    end
  end
end
