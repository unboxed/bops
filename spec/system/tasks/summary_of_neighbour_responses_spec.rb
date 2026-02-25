# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Summary of neighbour responses task", type: :system do
  let(:user) { create(:user, local_authority:) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/summary-of-neighbour-responses") }

  %i[planning_permission prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :in_assessment, local_authority:)
      end
      let!(:consultation) { planning_application.consultation }
      let!(:neighbour1) { create(:neighbour, address: "1, Test Lane, AAA111", consultation:) }
      let!(:neighbour2) { create(:neighbour, address: "2, Test Lane, AAA111", consultation:) }
      let!(:neighbour3) { create(:neighbour, address: "3, Test Lane, AAA111", consultation:) }

      before do
        sign_in(user)
        visit "/planning_applications/#{planning_application.reference}"
        click_link "Check and assess"
      end

      context "when there are no neighbour responses" do
        it "does not display the free text field" do
          within ".bops-sidebar" do
            click_link "Summary of neighbour responses"
          end

          expect(page).not_to have_field("Summary of design comments")
          expect(page).to have_content("Save and mark as complete")

          click_button "Save and mark as complete"

          expect(page).to have_content("Successfully saved summary of neighbour responses")
          expect(task.reload).to be_completed
          expect(planning_application.assessment_details.where(category: "neighbour_summary").length).to eq(1)
        end
      end

      context "when there are neighbour responses" do
        let!(:objection_response) { create(:neighbour_response, neighbour: neighbour1, summary_tag: "objection", tags: ["design", "access"]) }
        let!(:supportive_response1) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive", tags: ["design"]) }
        let!(:supportive_response2) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive", tags: ["access"]) }
        let!(:neutral_response) { create(:neighbour_response, neighbour: neighbour2, summary_tag: "neutral") }

        it "I can view the information on the neighbour responses page", :capybara do
          within ".bops-sidebar" do
            click_link "Summary of neighbour responses"
          end
          within(".govuk-notification-banner") do
            expect(page).to have_content("View neighbour responses")
            expect(page).to have_content("There are 4 neighbour responses")
          end

          expect(page).to have_content("Summary of neighbour responses")

          click_button "Design responses (2)"
          expect(page).to have_content(objection_response.redacted_response)
          expect(page).to have_content(supportive_response1.redacted_response)
          click_button "Design responses (2)"

          click_button "Access responses (2)"
          expect(page).to have_content(supportive_response2.redacted_response)
          expect(page).to have_content(objection_response.redacted_response)
          click_button "Access responses (2)"

          click_button "Untagged responses (1)"
          expect(page).to have_content(neutral_response.redacted_response)
        end

        it "I can save a draft of my summary" do
          within ".bops-sidebar" do
            click_link "Summary of neighbour responses"
          end

          fill_in "Summary of design comments", with: "Some design comments"
          fill_in "Summary of access comments", with: "Some access comments"

          click_button "Save changes"

          expect(page).to have_content("Successfully saved summary of neighbour responses")
          expect(task.reload).to be_in_progress

          expect(planning_application.assessment_details.where(category: "neighbour_summary").length).to be(1)
        end

        it "shows an error when only some summaries are filled on save and complete" do
          within ".bops-sidebar" do
            click_link "Summary of neighbour responses"
          end

          fill_in "Summary of design comments", with: "Some design comments"

          click_button "Save and mark as complete"

          expect(page).to have_content("Fill in all summaries of comments")
          expect(task.reload).not_to be_completed
        end

        it "can save and mark complete when all required summaries are filled" do
          within ".bops-sidebar" do
            click_link "Summary of neighbour responses"
          end

          fill_in "Summary of design comments", with: "Some design comments"
          fill_in "Summary of access comments", with: "Some access comments"
          fill_in "Summary of untagged comments", with: "Some untagged comments"

          click_button "Save and mark as complete"

          expect(page).to have_content("Successfully saved summary of neighbour responses")
          expect(task.reload).to be_completed
        end
      end
    end
  end
end
