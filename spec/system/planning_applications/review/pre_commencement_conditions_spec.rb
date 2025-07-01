# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing pre-commencement conditions" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: default_local_authority)
  end

  before { Current.user = assessor }

  let!(:condition_set) { planning_application.pre_commencement_condition_set }
  let!(:current_review) { condition_set.current_review }
  let!(:standard_condition) { create(:condition, condition_set:, title: "foo", validation_requests: [validate], position: 2) }
  let!(:other_condition) { create(:condition, :other, condition_set:, title: "bar", validation_requests: [validate], position: 1) }

  def validate
    travel_to(1.minute.from_now) do
      create(:pre_commencement_condition_validation_request, approved: true, planning_application:)
    end
  end

  context "when signed in as a reviewer" do
    before do
      current_review.complete!
      create(:recommendation, status: "assessment_complete", planning_application:)

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    context "when planning application is awaiting determination" do
      it "I can accept the planning officer's decision" do
        within("#review-pre-commencement-conditions") do
          expect(page).to have_content("Review pre-commencement conditions")
          expect(page).to have_content("Not started")
        end

        click_button "Review pre-commencement conditions"

        within("#review-pre-commencement-conditions") do
          within("ol.govuk-list") do
            within("li:nth-of-type(1)") do
              expect(page).to have_selector("h2", text: "bar")
              expect(page).to have_selector("p:first-child", text: other_condition.text)
              expect(page).to have_selector("h3 + p", text: other_condition.reason)
            end
            within("li:nth-of-type(2)") do
              expect(page).to have_selector("h2", text: "foo")
              expect(page).to have_selector("p:first-child", text: standard_condition.text)
              expect(page).to have_selector("h3 + p", text: standard_condition.reason)
            end
          end

          choose "Agree"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of pre-commencement conditions successfully updated")

        within("#review-pre-commencement-conditions") do
          expect(page).to have_content("Review pre-commencement conditions")
          expect(page).to have_content("Completed")
        end

        current_review.reload

        expect(current_review.action).to eq "accepted"
        expect(current_review.review_status).to eq "review_complete"
      end

      it "I can return with comments" do
        within("#review-pre-commencement-conditions") do
          expect(page).to have_content("Review pre-commencement conditions")
          expect(page).to have_content("Not started")
        end

        click_button "Review pre-commencement conditions"

        within("#review-pre-commencement-conditions") do
          choose "Return with comments"

          fill_in "Add a comment", with: "I don't think you've assessed conditions correctly"

          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review of pre-commencement conditions successfully updated")

        within("#review-pre-commencement-conditions") do
          expect(page).to have_content("Review pre-commencement conditions")
          expect(page).to have_content("Awaiting changes")
        end

        current_review.reload

        expect(current_review.action).to eq "rejected"
        expect(current_review.comment).to eq "I don't think you've assessed conditions correctly"
        expect(current_review.status).to eq "to_be_reviewed"

        sign_out(reviewer)
        sign_in(assessor)

        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"

        expect(page).to have_list_item_for(
          "Add pre-commencement conditions",
          with: "To be reviewed"
        )

        click_link "Add pre-commencement conditions"

        expect(page).to have_content("I don't think you've assessed conditions correctly")

        within "#condition_#{standard_condition.id}" do
          click_link "Cancel"
        end
      end
    end
  end
end
