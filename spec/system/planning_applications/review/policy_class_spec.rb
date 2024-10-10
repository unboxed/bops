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

    it "can make the policy class reviewed" do
      policy_class = create(:policy_class, section: "A", planning_application:)
      create(:policy, :complies, policy_class:)
      create(:review, owner: policy_class)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      expect(page).to have_selector("h1", text: "Review and sign-off")
      click_on "Review assessment of Part 1, Class A"

      choose "Accept"

      click_on "Save and mark as complete"

      expect(page).to have_text "Successfully updated policy class"
      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Completed")

      click_on "Review assessment of Part 1, Class A"

      expect(page).to have_text "Accept"

      click_on "Edit review of Part 1, Class A"

      click_on "Save and come back later"

      expect(page).to have_text "Successfully updated policy class"

      expect(page).to have_list_item_for(
        "Review assessment of Part 1, Class A",
        with: "Not started"
      )
    end

    it "can return legislation to officer and be updated when corrected" do
      policy_class = create(:policy_class,
        :complies,
        section: "A",
        planning_application:)
      create(:review, owner: policy_class)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      expect(page).to have_selector("h1", text: "Review and sign-off")
      click_on "Review assessment of Part 1, Class A"

      choose "Return to officer with comment"

      fill_in "Explain to the assessor why this needs reviewing", with: "Officer comment"

      click_on "Save and mark as complete"

      expect(page).to have_text "Successfully updated policy class"
      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Awaiting changes")

      click_on "Review assessment of Part 1, Class A"

      expect(page).to have_text "Return to officer with comment"

      click_on "Back"
      click_link("Sign off recommendation")
      choose("No (return the case for assessment)")

      fill_in(
        "Explain to the officer why the case is being returned",
        with: "reviewer comment"
      )

      click_button("Save and mark as complete")

      sign_in assessor

      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

      expect(list_item("Part 1, Class A")).to have_content("To be reviewed")

      click_link("Part 1, Class A")

      within("#reviewer_comment") do
        expect(page).to have_content("Reviewer comment:")
        expect(page).to have_content("Officer comment")
      end

      choose("policy_class_policies_attributes_0_status_complies")
      click_button("Save and mark as complete")

      expect(list_item("Part 1, Class A")).to have_content("Complete")

      click_on("Make draft recommendation")
      click_on("Update assessment")
      click_on("Review and submit recommendation")
      click_on("Submit recommendation")

      sign_in reviewer
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Updated")

      click_on "Review assessment of Part 1, Class A"
      choose "Accept"
      click_on "Save and mark as complete"

      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Completed")
    end

    context "when the assessor has added comments" do
      let(:policy_class) do
        create(
          :policy_class,
          section: "A",
          name: "Roof",
          planning_application:
        )
      end

      let(:policy) do
        create(
          :policy,
          policy_class:,
          description: "Policy description"
        )
      end

      before do
        Current.user = assessor

        create(
          :comment,
          commentable: policy,
          text: "policy comment",
          created_at: Time.zone.local(2020, 10, 15),
          updated_at: Time.zone.local(2020, 10, 15)
        )

        create(:review, owner: policy_class)

        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.reference}/review/tasks"
        click_on("Review assessment of Part 1, Class A")
      end

      it "displays policy_class with comments" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"
        click_on "Review assessment of Part 1, Class A"

        within("#planning-application-details") do
          expect(page).to have_content("Review - Part1, Class A")
        end

        expect(page).to have_content("Roof")

        expect(page).to have_selector("p", text: "Policy description")

        expect(page).to have_text(
          "Comment added on 15 October 2020 by Chuck The Assessor"
        )

        expect(page).to have_text("policy comment")
      end

      it "allows the reviewer to edit comments", capybara: true do
        travel_to(Time.zone.local(2020, 10, 16)) do
          click_button("Edit comment")

          expect(page).to have_field(
            "Comment added on 15 October 2020 by Chuck The Assessor",
            with: "policy comment"
          )

          fill_in(
            "Comment added on 15 October 2020 by Chuck The Assessor",
            with: ""
          )

          click_button("Update")

          expect(page).to have_content("Text can't be blank")

          fill_in(
            "Comment added on 15 October 2020 by Chuck The Assessor",
            with: "edited policy comment"
          )

          click_button("Update")

          expect(page).to have_content(
            "Comment updated on 16 October 2020 by Charlize The Reviever"
          )

          expect(page).to have_content("edited policy comment")

          find("span", text: "Previous comments").click

          expect(page).to have_content(
            "Comment added on 15 October 2020 by Chuck The Assessor"
          )

          expect(page).to have_content("policy comment")
        end
      end
    end

    it "displays policy class navigation" do
      prv = create(:policy_class, section: "A", planning_application:)
      policy_class = create(:policy_class, section: "B", planning_application:)
      nxt = create(:policy_class, section: "C", planning_application:)
      create(:policy, policy_class:)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      expect(page).to have_selector("h1", text: "Review and sign-off")
      click_on "Review assessment of Part 1, Class B"

      expect(page).to have_link "View previous class",
        href: edit_planning_application_review_policy_class_path(planning_application, prv)
      expect(page).to have_link "View next class",
        href: edit_planning_application_review_policy_class_path(planning_application, nxt)
    end

    it "can display errors" do
      policy_class = create(:policy_class, section: "A", planning_application:)
      create(:policy, policy_class:)
      create(:review, owner: policy_class, status: "complete")

      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      expect(page).to have_selector("h1", text: "Review and sign-off")
      click_on "Review assessment of Part 1, Class A"

      click_on "Save and mark as complete"

      expect(page).to have_text("All policies must be assessed")
    end

    context "when reviewing legislation with dynamic policies" do
      let!(:schedule) { create(:policy_schedule, number: 2, name: "Permitted development rights") }
      let!(:part1) { create(:policy_part, name: "Development within the curtilage of a dwellinghouse", number: 1, policy_schedule: schedule) }
      let!(:policy_classA) { create(:new_policy_class, section: "A", name: "enlargement, improvement or other alteration of a dwellinghouse", policy_part: part1) }

      let!(:policy_section1a) { create(:policy_section, section: "1a", description: "description for section 1a", new_policy_class: policy_classA) }
      let!(:policy_section1b) { create(:policy_section, section: "1b", description: "description for section 1b", new_policy_class: policy_classA) }
      let!(:policy_section2bii) { create(:policy_section, section: "2b(ii)", description: "description for section 2ab(ii)", new_policy_class: policy_classA) }

      let!(:pa_policy_section1a) { create(:planning_application_policy_section, :complies, policy_section: policy_section1a, planning_application:) }
      let!(:pa_policy_section1b) { create(:planning_application_policy_section, :complies, policy_section: policy_section1b, planning_application:) }
      let!(:pa_policy_section2bii) { create(:planning_application_policy_section, :does_not_comply, :with_comments, policy_section: policy_section2bii, planning_application:) }

      let!(:planning_application_policy_class) { create(:planning_application_policy_class, planning_application:, new_policy_class: policy_classA) }

      before do
        create(:review, owner_type: "PlanningApplicationPolicyClass", status: "complete", assessor: assessor, owner: planning_application_policy_class)
      end

      it "shows an error if no option is selected" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        click_on "Review assessment of Part 1, Class A"
        click_button "Save and mark as complete"
        expect(page).to have_selector("[role=alert] li", text: "Select an option")
      end

      it "allows the reviewer to accept" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        click_on "Review assessment of Part 1, Class A"
        expect(page).to have_selector("h1", text: "Review - Part 1, Class A")

        expect(page).to have_css("#policy-section-#{policy_section1a.id}")
        expect(page).to have_css("#policy-section-#{policy_section1b.id}")
        expect(page).to have_css("#policy-section-#{policy_section2bii.id}")

        expect(page).to have_field("planning-application-policy-sections-#{policy_section1a.id}-status-complies-field", disabled: true)
        expect(page).to have_field("planning-application-policy-sections-#{policy_section1b.id}-status-does-not-comply-field", disabled: true)
        expect(page).to have_field("planning-application-policy-sections-#{policy_section2bii.id}-status-does-not-comply-field", disabled: true)

        choose("Accept")
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

        click_on "Review assessment of Part 1, Class A"
        choose("Return to officer with comment")
        click_button("Save and mark as complete")
        expect(page).to have_selector("[role=alert] li", text: "Explain to the case officer why")

        fill_in "Explain to the assessor why this needs reviewing", with: "Rejection reason"
        click_button("Save and mark as complete")
        expect(page).to have_content("Review of publicity successfully added.")

        expect(list_item("Review assessment of Part 1, Class A")).to have_content("Awaiting changes")
        click_on "Review assessment of Part 1, Class A"
        click_on "Edit review of Part 1, Class A"
        fill_in "Explain to the assessor why this needs reviewing", with: "Rejection reason edited"
        click_button("Save and mark as complete")

        sign_in assessor

        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

        expect(list_item("Part 1, Class A")).to have_content("To be reviewed")

        click_link("Part 1, Class A")
        within("#reviewer_comment") do
          expect(page).to have_content("Reviewer comment:")
          expect(page).to have_content("Rejection reason edited")
        end

        within("#policy-section-#{policy_section2bii.id}") do
          choose(option: "complies")
        end
        click_button("Save and mark as complete")

        expect(list_item("Part 1, Class A")).to have_content("Complete")

        sign_in reviewer
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        expect(list_item("Review assessment of Part 1, Class A")).to have_content("Updated")

        click_on "Review assessment of Part 1, Class A"
        choose "Accept"
        click_on "Save and mark as complete"

        expect(list_item("Review assessment of Part 1, Class A")).to have_content("Completed")
      end
    end
  end
end
