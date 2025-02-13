# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing Policy Class", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }

  let(:reviewer) do
    create(
      :user,
      :reviewer,
      local_authority: default_local_authority,
      name: "Charlize The Reviever"
    )
  end

  let!(:assessor) { create(:user, name: "Chuck The Assessor", local_authority: default_local_authority) }
  let!(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      :with_recommendation,
      local_authority: default_local_authority,
      decision: :granted
    )
  end

  context "with a reviewer" do
    before do
      create(:decision, :ldc_granted)
      create(:decision, :ldc_refused)

      sign_in reviewer
    end

    context "when reviewing GPDO legislation" do
      let!(:schedule) { create(:policy_schedule, number: 2, name: "Permitted development rights") }
      let!(:part1) { create(:policy_part, name: "Development within the curtilage of a dwellinghouse", number: 1, policy_schedule: schedule) }
      let!(:policy_classA) { create(:policy_class, section: "A", name: "enlargement, improvement or other alteration of a dwellinghouse", policy_part: part1) }

      let!(:policy_section1a) { create(:policy_section, section: "1a", description: "description for section 1a", policy_class: policy_classA) }
      let!(:policy_section1b) { create(:policy_section, section: "1b", description: "description for section 1b", policy_class: policy_classA) }
      let!(:policy_section2bii) { create(:policy_section, section: "2b(ii)", description: "description for section 2bb(ii)", policy_class: policy_classA) }

      let!(:pa_policy_section1a) { create(:planning_application_policy_section, :complies, policy_section: policy_section1a, planning_application:) }
      let!(:pa_policy_section1b) { create(:planning_application_policy_section, :complies, policy_section: policy_section1b, planning_application:) }
      let!(:pa_policy_section2bii) { create(:planning_application_policy_section, :does_not_comply, :with_comments, policy_section: policy_section2bii, planning_application:) }

      let!(:planning_application_policy_class) { create(:planning_application_policy_class, planning_application:, policy_class: policy_classA) }

      before do
        create(:review, owner_type: "PlanningApplicationPolicyClass", status: "complete", assessor: assessor, owner: planning_application_policy_class)
      end

      it "shows an error if no option is selected" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        click_on "Review assessment against legislation"
        click_on "Review assessment of Part 1, Class A"
        click_button "Save and mark as complete"
        expect(page).to have_selector("[role=alert] li", text: "Select an option")
      end

      it "allows the reviewer to accept" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        click_on "Review assessment against legislation"
        click_on "Review assessment of Part 1, Class A"
        expect(page).to have_selector("h1", text: "Review - Part 1, Class A")

        expect(page).to have_css("#policy-section-#{policy_section1a.id}")
        expect(page).to have_css("#policy-section-#{policy_section1b.id}")
        expect(page).to have_css("#policy-section-#{policy_section2bii.id}")

        expect(page).to have_field("planning-application-policy-sections-#{policy_section1a.id}-status-complies-field", disabled: true)
        expect(page).to have_field("planning-application-policy-sections-#{policy_section1b.id}-status-does-not-comply-field", disabled: true)
        expect(page).to have_field("planning-application-policy-sections-#{policy_section2bii.id}-status-does-not-comply-field", disabled: true)

        choose "Agree"
        within("#policy-section-#{policy_section2bii.id}") do
          fill_in("Add comment", with: "Reviewer comment")
        end
        click_button("Save and come back later")

        expect(list_item("Review assessment of Part 1, Class A")).to have_content("In progress")
        click_link("Part 1, Class A")

        within("#policy-section-#{policy_section2bii.id}") do
          expect(page).to have_field("Add comment", with: "Reviewer comment")

          find("span", text: "Previous comments").click
          expect(page).to have_content("A comment")
        end

        click_button("Save and mark as complete")
        expect(page).to have_content("Review of publicity successfully added.")
        expect(list_item("Review assessment of Part 1, Class A")).to have_content("Completed")
      end

      it "allows the reviewer to reject with a comment" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        click_on "Review assessment against legislation"
        click_on "Review assessment of Part 1, Class A"
        choose "Return with comments"
        click_button("Save and mark as complete")
        expect(page).to have_selector("[role=alert] li", text: "Explain to the case officer why")

        fill_in "Add a comment", with: "Rejection reason"
        click_button("Save and mark as complete")
        expect(page).to have_content("Review of publicity successfully added.")

        expect(list_item("Review assessment of Part 1, Class A")).to have_content("Awaiting changes")
        click_on "Review assessment of Part 1, Class A"
        click_on "Edit review of Part 1, Class A"
        fill_in "Add a comment", with: "Rejection reason edited"
        click_button("Save and mark as complete")

        sign_in assessor

        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

        expect(list_item("Part 1, Class A")).to have_content("To be reviewed")

        # Updating policy section description
        policy_section2bii.update!(description: "A new description")

        click_link("Part 1, Class A")
        within("#reviewer_comment") do
          expect(page).to have_content("Reviewer comment:")
          expect(page).to have_content("Rejection reason edited")
        end

        within("#policy-section-#{policy_section2bii.id}") do
          # Description at time of assessment should be present
          expect(page).to have_content("description for section 2bb(ii)")
          expect(page).not_to have_content("A new description")

          choose(option: "complies")
        end
        click_button("Save and mark as complete")

        expect(list_item("Part 1, Class A")).to have_content("Complete")

        sign_in reviewer
        visit "/planning_applications/#{planning_application.reference}/review/tasks"
        click_on "Review assessment against legislation"

        expect(list_item("Review assessment of Part 1, Class A")).to have_content("Updated")
        click_link("Review assessment of Part 1, Class A")

        choose "Agree"
        click_on "Save and mark as complete"

        expect(list_item("Review assessment of Part 1, Class A")).to have_content("Completed")
      end
    end
  end
end
