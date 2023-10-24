# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing evidence of immunity" do
  let(:default_local_authority) { create(:local_authority, :default) }

  let(:reviewer) do
    create(
      :user,
      :reviewer,
      local_authority: default_local_authority,
      name: "Charlize The Reviever"
    )
  end

  let(:assessor) { create(:user, local_authority: default_local_authority) }

  let(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      :with_recommendation,
      :with_immunity,
      local_authority: default_local_authority,
      decision: :granted
    )
  end

  context "when there's not an evidence of immunity" do
    before do
      sign_in reviewer
      visit(planning_application_review_tasks_path(planning_application))
    end

    it "I cannot view the link of Review evidence of immunity page" do
      expect(page).not_to have_link("Review evidence of immunity")
    end
  end

  context "when there's an evidence of immunity" do
    before do
      create(:review_immunity_detail, :evidence, immunity_detail: planning_application.immunity_detail, assessor:)
      create(:evidence_group, :with_document, tag: "utility_bill", missing_evidence: true, missing_evidence_entry: "gaps everywhere", immunity_detail: planning_application.immunity_detail)
      create(:evidence_group, :with_document, tag: "building_control_certificate", end_date: nil, immunity_detail: planning_application.immunity_detail)

      sign_in reviewer
      visit(planning_application_review_tasks_path(planning_application))
    end

    context "when planning application is awaiting determination" do
      it "I can view the information on the review evidence of immunity page" do
        expect(page).to have_list_item_for(
          "Review evidence of immunity",
          with: "Not started"
        )

        click_link "Review evidence of immunity"

        within(".govuk-breadcrumbs__list") do
          expect(page).to have_content("Review")
          expect(page).to have_content("Review evidence of immunity")
        end

        expect(page).to have_current_path(
          edit_planning_application_review_immunity_detail_path(planning_application, ReviewImmunityDetail.last)
        )

        expect(page).to have_content("Review evidence of immunity")
        expect(page).to have_content("Application number: #{planning_application.reference}")
        expect(page).to have_content(planning_application.full_address)

        expect(page).to have_content("Were the works carried out more than 4 years ago? Yes")
        expect(page).to have_content("Have the works been completed? Yes")
        expect(page).to have_content("When were the works completed? 01/02/2015")
        expect(page).to have_content("Has anyone ever attempted to conceal the changes? No")
        expect(page).to have_content("Has enforcement action been taken about these changes? No")

        click_button "Utility bills (1)"
        utility_bill_group = planning_application.immunity_detail.evidence_groups.where(tag: "utility_bill").first

        within(open_accordion_section) do
          expect(page).to have_content(utility_bill_group.start_date.to_fs(:day_month_year_slashes))
          expect(page).to have_content(utility_bill_group.end_date.to_fs(:day_month_year_slashes))

          expect(page).to have_content("Missing evidence (gap in time): gaps everywhere")

          expect(page).to have_content("This is my proof")

          expect(page).to have_content(utility_bill_group.documents.first.numbers)
        end
      end

      it "I can save and come back later when adding my review or editing the evidence of immunity" do
        click_link "Review evidence of immunity"

        choose "Accept"

        click_button "Save and come back later"
        expect(page).to have_content("Review immunity details was successfully updated")

        expect(page).to have_list_item_for(
          "Review evidence of immunity",
          with: "In progress"
        )

        click_link "Review evidence of immunity"

        expect(page).to have_checked_field("Accept")

        choose "Return to officer with comment"

        fill_in "Explain to the assessor why this needs reviewing", with: "Please re-assess"

        click_button "Save and come back later"
        expect(page).to have_content("Review immunity details was successfully updated")

        expect(page).to have_list_item_for(
          "Review evidence of immunity",
          with: "In progress"
        )

        click_link "Review evidence of immunity"

        expect(page).to have_checked_field("Return to officer with comment")

        expect(page).to have_content("Please re-assess")
      end

      it "I can save and mark as complete when adding my review to accept the review evidence of immunity response" do
        click_link "Review evidence of immunity"

        choose "Accept"

        click_button "Save and mark as complete"

        expect(page).to have_list_item_for(
          "Review evidence of immunity",
          with: "Completed"
        )

        click_link "Review evidence of immunity"

        expect(page).not_to have_content("Save and mark as complete")
      end

      it "when I return it to officer with comments, they can see my comments" do
        click_link "Review evidence of immunity"

        choose "Return to officer with comment"

        fill_in "Explain to the assessor why this needs reviewing", with: "Please re-assess"

        click_button "Save and mark as complete"

        click_link "Application"
        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "To be reviewed"
        )

        click_link "Evidence of immunity"
        find("span", text: "See immunity detail checks").click

        expect(page).to have_content("Please re-assess")
      end

      it "I can edit comments" do
        utility_bill_group = planning_application.immunity_detail.evidence_groups.where(tag: "utility_bill").first

        comment = create(
          :comment,
          commentable: utility_bill_group,
          created_at: DateTime.new(2022, 12, 19),
          text: "test"
        )

        click_link "Review evidence of immunity"

        click_button "Utility bills (1)"

        within(open_accordion_section) do
          expect(page).to have_content("test")

          click_button "Edit comment"

          fill_in "Comment added on #{comment.created_at.to_date.to_fs} by",
            with: ""

          click_button "Update"

          expect(page).to have_content "Text can't be blank"

          fill_in "Comment added on #{comment.created_at.to_date.to_fs} by",
            with: "This is a new comment now"

          click_button "Update"

          expect(page).to have_content("This is a new comment now")
        end

        click_link "Review"
        click_link "Review evidence of immunity"

        click_button "Utility bills (1)"

        within(open_accordion_section) do
          expect(page).to have_content("This is a new comment now")

          find("span", text: "Previous comments").click

          expect(page).to have_content("test")
        end
      end
    end
  end
end
