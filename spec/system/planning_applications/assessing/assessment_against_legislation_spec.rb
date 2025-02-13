# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assessment against legislation", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: local_authority) }

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
        visit "/planning_applications/#{planning_application.reference}"
      end

      context "when assessing GPDO legislation" do
        let!(:schedule) { create(:policy_schedule, number: 2, name: "Permitted development rights") }
        let!(:part1) { create(:policy_part, name: "Development within the curtilage of a dwellinghouse", number: 1, policy_schedule: schedule) }
        let!(:part2) { create(:policy_part, name: "Minor operations", number: 2, policy_schedule: schedule) }
        let!(:policy_classA) { create(:policy_class, section: "A", name: "enlargement, improvement or other alteration of a dwellinghouse", policy_part: part1) }
        let!(:policy_classB) { create(:policy_class, section: "B", name: "additions etc to the roof of a dwellinghouse", policy_part: part1) }

        before do
          create(:policy_class, section: "A", name: "gates, fences, walls etc", policy_part: part2)
        end

        it "lets the assessor add the relevant classes" do
          click_link("Check and assess")
          within("#assess-against-legislation-tasks") do
            click_link("Add new assessment area")
          end

          click_button("Continue")
          expect(page).to have_content("You must select a part to continue")

          choose("Part 1 - Development within the curtilage of a dwellinghouse")
          click_button("Continue")

          expect(page).not_to have_content("Class A - gates, fences, walls etc")
          check("Class A - enlargement, improvement or other alteration of a dwellinghouse")
          check("Class B - additions etc to the roof of a dwellinghouse")
          click_button("Add classes")

          expect(page).to have_content("Policy classes have been successfully added")

          within("#assess-against-legislation-tasks") do
            click_link("Add new assessment area")
          end

          choose("Part 1 - Development within the curtilage of a dwellinghouse")
          click_button("Continue")
          expect(page).to have_checked_field("Class A - enlargement, improvement or other alteration of a dwellinghouse", disabled: true)
          expect(page).to have_checked_field("Class B - additions etc to the roof of a dwellinghouse", disabled: true)

          click_link("Back")
          choose("Part 2 - Minor operations")
          click_button("Continue")

          expect(page).not_to have_content("Class A - enlargement, improvement or other alteration of a dwellinghouse")
          check("Class A - gates, fences, walls etc")
          click_button("Add classes")

          within("#assess-against-legislation-tasks") do
            expect(page).to have_link("Part 1, Class A")
            expect(page).to have_link("Part 1, Class B")
            expect(page).to have_link("Part 2, Class A")
          end
        end

        it "lets the assessor remove a class to assess" do
          create(:planning_application_policy_class, planning_application:, policy_class: policy_classA)

          click_link("Check and assess")
          within("#assess-against-legislation-tasks") do
            click_link("Part 1, Class A")
          end

          accept_confirm do
            click_button("Remove class from assessment")
          end
          within("#assess-against-legislation-tasks") do
            expect(page).not_to have_content("Part 1, Class A")
          end

          expect(planning_application.planning_application_policy_classes.length).to eq(0)

          click_link("Add new assessment area")
          choose("Part 1 - Development within the curtilage of a dwellinghouse")
          click_button("Continue")
          expect(page).to have_unchecked_field("Class A - enlargement, improvement or other alteration of a dwellinghouse")
        end

        context "when assessing the policy sections" do
          let!(:policy_section1a) { create(:policy_section, section: "1a", description: "description for section 1a", policy_class: policy_classA) }
          let!(:policy_section1b) { create(:policy_section, section: "1b", description: "description for section 1b", policy_class: policy_classA) }
          let!(:policy_section2bii) { create(:policy_section, section: "2b(ii)", description: "description for section 2ab(ii)", policy_class: policy_classA) }

          before do
            create(:planning_application_policy_class, planning_application:, policy_class: policy_classA)
          end

          it "lets the user save draft and then mark as complete" do
            travel_to(Time.zone.local(2022, 9, 1, 14))
            click_link("Check and assess")

            within("#assess-against-legislation-tasks") do
              expect(page).to have_list_item_for("Part 1, Class A", with: "Not started")
              click_link("Part 1, Class A")
            end

            within("#policy-section-#{policy_section1a.id}") do
              expect(page).to have_content("A.1a")
              expect(page).to have_content("description for section 1a")
              choose(option: "complies")
              fill_in("Add comment", with: "My first comment")
            end
            within("#policy-section-#{policy_section1b.id}") do
              expect(page).to have_content("A.1b")
              expect(page).to have_content("description for section 1b")
              choose(option: "does_not_comply")
              fill_in("Add comment", with: "My second comment")
            end

            click_button("Save and mark as complete")

            expect(page).to have_content("All policies must be assessed")

            click_button("Save and come back later")

            expect(page).to have_content("Policy class was successfully updated")
            expect(page).to have_list_item_for("Part 1, Class A", with: "In progress")

            # Updating policy section description
            policy_section1a.update!(description: "A new description")

            click_link("Part 1, Class A")
            within("#policy-section-#{policy_section1a.id}") do
              # Description at time of assessment should be present
              expect(page).to have_content("description for section 1a")
              expect(page).not_to have_content("A new description")

              expect(page).to have_field("Add comment", with: "My first comment")
              fill_in("Add comment", with: "Updated first comment")
            end
            within("#policy-section-#{policy_section1b.id}") do
              expect(page).to have_field("Add comment", with: "My second comment")
              fill_in("Add comment", with: "Updated second comment")
            end

            within("#policy-section-#{policy_section2bii.id}") do
              choose(option: "does_not_comply")
            end
            click_button("Save and mark as complete")

            expect(page).to have_content("Policy class was successfully updated")
            expect(page).to have_list_item_for("Part 1, Class A", with: "Completed")

            click_link("Part 1, Class A")
            within("#policy-section-#{policy_section1a.id}") do
              expect(page).to have_field("Add comment", with: "Updated first comment")
              find("span", text: "Previous comments").click
              expect(page).to have_content("Comment added on 1 September 2022 by Alice Smith")
              expect(page).to have_content("My first comment")
            end
            within("#policy-section-#{policy_section1b.id}") do
              expect(page).to have_field("Add comment", with: "Updated second comment")
              find("span", text: "Previous comments").click
              expect(page).to have_content("Comment added on 1 September 2022 by Alice Smith")
              expect(page).to have_content("My second comment")
            end
            expect(page).to have_checked_field("planning-application-policy-sections-#{policy_section1a.id}-status-complies-field")
            expect(page).to have_checked_field("planning-application-policy-sections-#{policy_section1b.id}-status-does-not-comply-field")
            expect(page).to have_checked_field("planning-application-policy-sections-#{policy_section2bii.id}-status-does-not-comply-field")
          end

          context "with comments" do
            let(:comment1) { create(:comment, text: "Original comment") }
            let(:comment2) { create(:comment, text: "Updated comment") }
            let(:comment3) { create(:comment, text: "Current comment") }
            let(:planning_application_policy_section) { create(:planning_application_policy_section, policy_section: policy_section1a, planning_application:) }

            before do
              Current.user = assessor

              travel_to(Time.zone.local(2022, 9, 1))
              planning_application_policy_section.comments << comment1

              travel_to(Time.zone.local(2022, 10, 1))
              planning_application_policy_section.comments << comment2

              travel_to(Time.zone.local(2022, 11, 1))
              planning_application_policy_section.comments << comment3
              sign_in(assessor)
            end

            it "shows the updated comment and previous comments" do
              click_link("Check and assess")
              click_link("Part 1, Class A")

              within("#policy-section-#{policy_section1a.id}") do
                expect(page).to have_field("Add comment", with: "Current comment")
                find("span", text: "Previous comments").click

                within("#comment_#{comment1.id}") do
                  expect(page).to have_content("Comment added on 1 September 2022 by Alice Smith")
                  expect(page).to have_content("Original comment")
                end

                within("#comment_#{comment2.id}") do
                  expect(page).to have_content("Comment updated on 1 October 2022 by Alice Smith")
                  expect(page).to have_content("Updated comment")
                end
              end

              # Ignores blank values
              within("#policy-section-#{policy_section1a.id}") do
                fill_in("Add comment", with: "")
              end
              click_button("Save and come back later")
              click_link("Part 1, Class A")

              within("#policy-section-#{policy_section1a.id}") do
                expect(page).to have_field("Add comment", with: "Current comment")
              end
              expect(planning_application_policy_section.comments.length).to eq(3)
            end
          end
        end
      end
    end
  end

  context "when planning application is planning permission" do
    let(:planning_application) do
      create(
        :planning_application,
        :planning_permission,
        :in_assessment,
        :with_constraints,
        local_authority:,
        api_user:
      )
    end

    before do
      assessor =
        create(
          :user,
          :assessor,
          local_authority:,
          name: "Alice Smith"
        )

      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}"
    end

    it "doesn't show policy classes" do
      click_link "Check and assess"

      expect(page).to have_content("Assess against policies and guidance")
      expect(page).not_to have_content("Add new assessment area")
    end
  end

  def add_policy_classes(policy_classes)
    within("#assess-against-legislation-tasks") do
      click_link("Add new assessment area")
    end
    choose("Part 1 - Development within the curtilage of a dwellinghouse")
    click_button("Continue")
    policy_classes.each { |policy_class| check(policy_class) }
    click_button("Add classes")
  end
end
