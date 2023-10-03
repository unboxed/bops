# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assessment against legislation" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let(:local_authority) { create(:local_authority, :default) }

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      :with_constraints,
      local_authority:,
      api_user:
    )
  end

  context "when planning application is not planning permission" do
    context "when I'm signed in as an assessor" do
      let(:assessor) do
        create(
          :user,
          :assessor,
          local_authority:,
          name: "Alice Smith"
        )
      end

      let(:assessor2) do
        create(
          :user,
          :assessor,
          local_authority:,
          name: "Bella Jones"
        )
      end

      before do
        sign_in(assessor)
        visit planning_application_path(planning_application)
      end

      it "warns the user about unsaved changes" do
        click_link("Check and assess")
        click_link("Add assessment area")
        click_link("Back")
        click_link("Add assessment area")
        choose("Part 1 - Development within the curtilage of a dwellinghouse")
        dismiss_confirm { click_link("Back") }
        click_button("Continue")
        click_link("Back")
        click_button("Continue")

        check(
          "Class A - enlargement, improvement or other alteration of a dwellinghouse"
        )

        dismiss_confirm { click_link("Back") }
        click_button("Add classes")

        expect(page).to have_content("Policy classes have been successfully added")

        click_link("Part 1, Class A")
        click_link("Back")
        click_link("Part 1, Class A")
        choose("policy_class_policies_attributes_0_status_complies")
        dismiss_confirm { click_link("Back") }
        click_button("Save and come back later")

        expect(page).to have_content("Successfully updated policy class")
      end

      it "lets the user add policy classes once only" do
        click_link("Check and assess")
        add_policy_classes(["Class D - porches"])

        expect(page).to have_content("Part 1, Class D").once

        click_link("Add assessment area")
        choose("Part 1 - Development within the curtilage of a dwellinghouse")
        click_button("Continue")

        expect(page).to have_checked_field("Class D - porches", disabled: true)

        check("Class G - chimneys, flues etc on a dwellinghouse")
        click_button("Add classes")

        expect(page).to have_content("Part 1, Class D").once
        expect(page).to have_content("Part 1, Class G").once
      end

      it "lets the user remove policy class" do
        click_link("Check and assess")
        add_policy_classes(["Class D - porches"])
        expect(page).to have_content("Part 1, Class D").once

        click_link("Part 1, Class D")

        accept_confirm do
          click_button("Remove class from assessment")
        end

        expect(page).to have_content("Policy class has been removed.")
      end

      it "displays the class title" do
        click_link("Check and assess")

        add_policy_classes(
          [
            "Class A - enlargement, improvement or other alteration of a dwellinghouse",
            "Class B - additions etc to the roof of a dwellinghouse"
          ]
        )

        click_link("Part 1, Class A")
        expect(page).to have_content("Enlargement, improvement or other alteration of a dwellinghouse")
        within("h1") do
          expect(page).to have_content("Assess - Part 1, Class A")
        end

        click_link("Back")
        click_link("Part 1, Class B")
        expect(page).to have_content("Additions etc to the roof of a dwellinghouse")
        within("h1") do
          expect(page).to have_content("Assess - Part 1, Class B")
        end
      end

      it "displays the constraints with edit" do
        click_link("Check and assess")
        add_policy_classes(["Class D - porches"])

        click_link("Part 1, Class D")
        within(".govuk-accordion__section") do
          click_button("Constraints")
          expect(page).to have_content("Conservation area")
          expect(page).to have_content("Listed building outline")

          expect(page).to have_link("Edit constraints",
                                    href: planning_application_constraints_path(planning_application))
        end
      end

      it "lets the user add comments" do
        travel_to(Time.zone.local(2022, 9, 1))
        click_link("Check and assess")
        add_policy_classes(["Class D - porches"])
        click_link("Part 1, Class D")

        within(row_with_content("D.1a")) do
          fill_in("Add comment", with: "New comment")
        end

        click_button("Save and come back later")
        click_link("Part 1, Class D")

        within(row_with_content("D.1a")) do
          expect(page).to have_field(
            "Comment added on 1 September 2022 by Alice Smith",
            with: "New comment"
          )

          expect(page).not_to have_content("Previous comments")
        end

        expect(row_with_content("D.1b")).to have_field("Add comment", with: "")

        click_link("Log out")
        travel_to(Time.zone.local(2022, 9, 2))
        sign_in(assessor2)
        visit planning_application_path(planning_application)
        click_link("Check and assess")
        click_link("Part 1, Class D")

        within(row_with_content("D.1a")) do
          fill_in(
            "Comment added on 1 September 2022 by Alice Smith",
            with: ""
          )
        end

        click_button("Save and come back later")

        expect(page).to have_content("Existing comment can't be blank")

        within(row_with_content("D.1a")) do
          expect(page).to have_content("can't be blank")

          expect(page).to have_field(
            "Comment added on 1 September 2022 by Alice Smith",
            with: ""
          )
        end
      end

      context "when user updates a comment" do
        let(:policy_class) { create(:policy_class, planning_application:) }
        let(:policy) { create(:policy, policy_class:) }
        let(:comment1) { create(:comment, text: "Original comment") }
        let(:comment2) { create(:comment, text: "Updated comment") }

        before do
          Current.user = assessor

          travel_to(Time.zone.local(2022, 9, 1))
          policy.comments << comment1

          travel_to(Time.zone.local(2022, 10, 1))
          policy.comments << comment2
        end

        it "shows the updated comment and previous comments" do
          click_link("Check and assess")
          click_link("Part 1, Class A")

          within(row_with_content("A.1A")) do
            expect(page).to have_field(
              "Comment updated on 1 October 2022 by Alice Smith",
              with: "Updated comment"
            )

            find("span", text: "Previous comments").click

            expect(page).to have_content(
              "Comment added on 1 September 2022 by Alice Smith"
            )

            expect(page).to have_content("Original comment")
          end
        end
      end

      it "lets the user save draft and then mark as complete" do
        travel_to(Time.zone.local(2022, 9, 1))

        expect(list_item("Check and assess")).to have_content("Not started")

        click_link("Check and assess")
        add_policy_classes(["Class D - porches"])
        click_link("Part 1, Class D")

        within(row_with_content("D.1a")) do
          fill_in("Add comment", with: "Test comment")
        end

        choose("policy_class_policies_attributes_0_status_complies")
        choose("policy_class_policies_attributes_1_status_complies")
        choose("policy_class_policies_attributes_2_status_complies")
        choose("policy_class_policies_attributes_3_status_complies")
        choose("policy_class_policies_attributes_4_status_complies")
        click_button("Save and mark as complete")

        expect(page).to have_content("All policies must be assessed")

        within(row_with_content("D.1a")) do
          expect(page).to have_field("Add comment", with: "Test comment")
        end

        click_button("Save and come back later")

        expect(page).to have_content("Successfully updated policy class")
        expect(page).to have_list_item_for("Part 1, Class D", with: "In progress")

        click_link("Part 1, Class D")
        click_button("Save and mark as complete")

        expect(page).to have_content("All policies must be assessed")

        within(row_with_content("D.1a")) do
          expect(page).to have_field(
            "Comment added on 1 September 2022 by Alice Smith",
            with: "Test comment"
          )
        end

        choose("policy_class_policies_attributes_5_status_complies")
        click_button("Save and mark as complete")

        expect(page).to have_content("Successfully updated policy class")
        expect(page).to have_list_item_for("Part 1, Class D", with: "Completed")

        click_link("Part 1, Class D")
        expect(page).to have_content("Comment added on 1 September 2022 by Alice Smith")
        expect(page).to have_content("Test comment")

        expect(page).not_to have_field(
          "Comment added on 1 September 2022 by Alice Smith",
          with: "Test comment"
        )

        expect(page).not_to have_selector(
          "#policy_class_policies_attributes_0_status_does_not_comply"
        )

        click_link("Edit assessment")

        expect(page).to have_field(
          "Comment added on 1 September 2022 by Alice Smith",
          with: "Test comment"
        )

        expect(page).to have_selector(
          "#policy_class_policies_attributes_0_status_does_not_comply"
        )

        click_link("Application")

        expect(list_item("Check and assess")).to have_content("In progress")
      end

      it "lets the user scroll between policy classes" do
        travel_to(Time.zone.local(2022, 9, 1))

        click_link("Check and assess")

        add_policy_classes(
          [
            "Class D - porches",
            "Class F - hard surfaces incidental to the enjoyment of a dwellinghouse"
          ]
        )

        click_link("Part 1, Class D")

        expect(page).not_to have_content("Save changes and view previous class")

        within(row_with_content("D.1a")) do
          fill_in("Add comment", with: "Test comment")
        end

        click_button("Save changes and view next class")

        expect(page).to have_content("Part 1, Class F")
        expect(page).not_to have_content("Save changes and view next class")

        click_button("Save changes and view previous class")

        expect(page).to have_content("Part 1, Class D")

        expect(page).to have_field(
          "Comment added on 1 September 2022 by Alice Smith",
          with: "Test comment"
        )

        choose("policy_class_policies_attributes_0_status_complies")
        choose("policy_class_policies_attributes_1_status_complies")
        choose("policy_class_policies_attributes_2_status_complies")
        choose("policy_class_policies_attributes_3_status_complies")
        choose("policy_class_policies_attributes_4_status_complies")
        choose("policy_class_policies_attributes_5_status_complies")
        click_button("Save and mark as complete")
        click_link("Part 1, Class F")
        choose("policy_class_policies_attributes_0_status_complies")
        choose("policy_class_policies_attributes_1_status_complies")
        choose("policy_class_policies_attributes_2_status_complies")
        choose("policy_class_policies_attributes_3_status_complies")
        choose("policy_class_policies_attributes_4_status_complies")
        click_button("Save and mark as complete")
        click_link("Part 1, Class D")

        expect(page).not_to have_content("View previous class")

        click_link("View next class")

        expect(page).to have_content("Part 1, Class F")
        expect(page).not_to have_content("View next class")

        click_link("View previous class")

        expect(page).to have_content("Part 1, Class D")
      end

      it "lets the user delete comments" do
        travel_to(Time.zone.local(2022, 9, 1))
        click_link("Check and assess")
        add_policy_classes(["Class D - porches"])
        click_link("Part 1, Class D")

        within(row_with_content("D.1a")) do
          fill_in("Add comment", with: "Test comment")
        end

        click_button("Save and come back later")
        click_link("Part 1, Class D")

        within(row_with_content("D.1a")) do
          click_button("Delete comment")

          expect(page).to have_field("Add comment", with: "")

          find("span", text: "Previous comments").click

          expect(page).to have_content(
            "Comment added on 1 September 2022 by Alice Smith"
          )

          expect(page).to have_content("Test comment")
          expect(page).to have_content("Comment deleted")

          fill_in("Add comment", with: "New comment")
        end

        click_button("Save and come back later")
        click_link("Part 1, Class D")

        within(row_with_content("D.1a")) do
          expect(page).to have_field(
            "Comment added on 1 September 2022 by Alice Smith",
            with: "New comment"
          )
        end
      end
    end

    context "when I'm signed in as a reviewer" do
      let!(:reviewer) do
        create(
          :user,
          :reviewer,
          local_authority:
        )
      end

      before do
        sign_in(reviewer)
        visit planning_application_path(planning_application)
      end

      it "displays the constraints without edit" do
        click_link("Check and assess")
        add_policy_classes(["Class D - porches"])

        click_link("Part 1, Class D")
        within(".govuk-accordion__section") do
          click_button("Constraints")
          expect(page).to have_content("Conservation area")
          expect(page).to have_content("Listed building outline")

          expect(page).not_to have_link("Edit constraints",
                                        href: planning_application_constraints_path(planning_application))
        end
      end
    end
  end

  context "when planning application is planning permission" do
    before do
      assessor =
        create(
          :user,
          :assessor,
          local_authority:,
          name: "Alice Smith"
        )

      planning_permission = create(:application_type, :planning_permission)
      planning_application.update(application_type: planning_permission)

      sign_in(assessor)
      visit planning_application_path(planning_application)
    end

    it "doesn't show policy classes" do
      click_link "Check and assess"

      expect(page).to have_content("Assess against policies and guidance")
      expect(page).not_to have_content("Add assessment area")
    end
  end

  def add_policy_classes(policy_classes)
    click_link("Add assessment area")
    choose("Part 1 - Development within the curtilage of a dwellinghouse")
    click_button("Continue")
    policy_classes.each { |policy_class| check(policy_class) }
    click_button("Add classes")
  end
end
