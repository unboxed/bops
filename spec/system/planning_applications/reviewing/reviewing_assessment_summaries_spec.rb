# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing assessment summaries" do
  let(:local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority: local_authority,
      name: "Alice Smith"
    )
  end

  let!(:reviewer) do
    create(
      :user,
      :reviewer,
      local_authority: local_authority,
      name: "Bella Jones"
    )
  end

  let!(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      local_authority: local_authority,
      decision: :granted
    )
  end

  before do
    create(
      :recommendation,
      planning_application: planning_application,
      created_at: Time.zone.local(2022, 11, 27, 12, 30)
    )

    sign_in(reviewer)
  end

  context "when assessor filled out summaries" do
    before do
      create(
        :assessment_detail,
        :summary_of_work,
        assessment_status: :complete,
        planning_application: planning_application,
        user: assessor,
        entry: "summary of works"
      )

      create(
        :assessment_detail,
        :site_description,
        assessment_status: :complete,
        planning_application: planning_application,
        user: assessor,
        entry: "site description"
      )

      create(:consultee, planning_application: planning_application)

      create(
        :assessment_detail,
        :consultation_summary,
        assessment_status: :complete,
        planning_application: planning_application,
        user: assessor,
        entry: "consultation summary",
        created_at: Time.zone.local(2022, 11, 27, 12, 15)
      )

      create(
        :assessment_detail,
        :additional_evidence,
        assessment_status: :complete,
        planning_application: planning_application,
        user: assessor,
        entry: "additional evidence"
      )
    end

    it "allows reviewer to submit correctly filled out form" do
      travel_to(Time.zone.local(2022, 11, 28, 12, 30))
      visit(planning_application_review_tasks_path(planning_application))

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "Not started"
      )

      click_link("Review assessment summaries")
      click_button("Save and come back later")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "Not started"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Summary of works")) do
        expect(find(".govuk-tag")).to have_content("Complete")

        choose("Accept")
      end

      click_button("Save and mark as complete")

      expect(page).to have_content(
        "Additional evidence reviewer verdict can't be blank"
      )

      expect(page).to have_content(
        "Site description reviewer verdict can't be blank"
      )

      expect(page).to have_content(
        "Consultation summary reviewer verdict can't be blank"
      )

      click_button("Save and come back later")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "In progress"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Site description")) do
        choose("Edit to accept")
      end

      click_button("Save and come back later")

      expect(page).to have_content("Site description entry must be edited")

      within(find("fieldset", text: "Site description")) do
        fill_in("Update site description", with: "")
      end

      click_button("Save and come back later")

      expect(page).to have_content("Site description entry can't be blank")

      within(find("fieldset", text: "Site description")) do
        fill_in("Update site description", with: "edited site description")
      end

      click_button("Save and come back later")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "In progress"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Consultation")) do
        choose("Return to officer with comment")
      end

      click_button("Save and come back later")

      expect(page).to have_content(
        "Consultation summary comment text can't be blank"
      )

      within(find("fieldset", text: "Consultation")) do
        fill_in(
          "Explain to the assessor why this needs reviewing",
          with: "consultation comment"
        )
      end

      click_button("Save and come back later")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "In progress"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Additional evidence")) do
        choose("Accept")
      end

      click_button("Save and mark as complete")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "Checked"
      )

      click_link("Sign-off recommendation")
      choose("recommendation_challenged_true")
      fill_in("Review comment", with: "recommendation challenged")
      click_button("Save and mark as complete")
      click_link("Review assessment summaries")

      within(find("fieldset", text: "Consultation")) do
        expect(find(".govuk-tag")).to have_content("To be reviewed")
      end

      click_link("Log out")
      sign_in(assessor)
      visit(planning_application_path(planning_application))

      expect(page).to have_list_item_for(
        "Check and assess", with: "To be reviewed"
      )

      click_link("Check and assess")

      expect(page).to have_list_item_for(
        "Summary of consultation", with: "To be reviewed"
      )

      click_link("Summary of consultation")

      expect(page).to have_content("Bella Jones marked this for review")
      expect(page).to have_content("28 November 2022 12:30")
      expect(page).to have_content("consultation comment")

      expect(page).to have_field(
        "assessment-detail-entry-field",
        with: "consultation summary"
      )

      fill_in(
        "assessment-detail-entry-field",
        with: "updated consultation summary"
      )

      click_button("Save and mark as complete")

      expect(page).to have_content("Consultation summary successfully updated.")

      expect(page).to have_list_item_for(
        "Summary of consultation", with: "Complete"
      )

      click_link("Application")

      click_link("Check and assess")
      click_link("Make draft recommendation")

      click_button("Update assessment")
      click_link("Submit recommendation")
      click_button("Submit recommendation")
      click_link("Log out")
      sign_in(reviewer)
      visit(planning_application_path(planning_application))

      expect(page).to have_list_item_for(
        "Review and sign-off", with: "Updated"
      )

      click_link("Review and sign-off")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "Updated"
      )

      click_link("Review assessment summaries")
      expect(page).to have_content("updated consultation summary")

      within(find("fieldset", text: "Consultation")) do
        expect(find(".govuk-tag")).to have_content("Updated")

        find("span", text: "See previous summaries").click

        expect(page).to have_content("Alice Smith created consultation summary")
        expect(page).to have_content("27 November 2022 12:15")
        expect(page).to have_content("Bella Jones marked this for review")
        expect(page).to have_content("28 November 2022 12:30")

        choose("Accept")
      end

      click_button("Save and mark as complete")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "Checked"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Consultation")) do
        expect(find(".govuk-tag")).to have_content("Complete")
      end

      click_link("Review")
      click_link("Sign-off recommendation")
      choose("recommendation_challenged_false")
      click_button("Save and mark as complete")

      click_link("Review assessment summaries")
      click_link("Edit review")

      within(find("fieldset", text: "Consultation")) do
        choose("Return to officer with comment")

        fill_in(
          "Explain to the assessor why this needs reviewing",
          with: "new consultation comment"
        )
      end

      click_button("Save and mark as complete")

      expect(page).to have_content(
        "You agreed with the assessor recommendation, to request any change you must change your decision on the Sign-off recommendation screen"
      )

      click_link("Review")
      click_link("Sign-off recommendation")
      choose("recommendation_challenged_true")
      fill_in("Review comment", with: "recommendation challenged again")
      click_button("Save and mark as complete")
      click_link("Review assessment summaries")
      click_link("Edit review")

      within(find("fieldset", text: "Consultation")) do
        choose("Return to officer with comment")

        fill_in(
          "Explain to the assessor why this needs reviewing",
          with: "new consultation comment"
        )
      end

      click_button("Save and mark as complete")

      expect(page).to have_content("Review saved")
    end
  end

  context "when assessor didn't fill out summaries" do
    it "allows reviewer to submit correctly filled out form" do
      visit(planning_application_review_tasks_path(planning_application))

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "Not started"
      )

      click_link("Review assessment summaries")
      click_button("Save and come back later")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "Not started"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Summary of works")) do
        expect(find(".govuk-tag")).to have_content("Not started")

        choose("Accept")
      end

      click_button("Save and mark as complete")

      expect(page).to have_content(
        "Additional evidence reviewer verdict can't be blank"
      )

      expect(page).to have_content(
        "Site description reviewer verdict can't be blank"
      )

      expect(page).to have_content(
        "Consultation summary reviewer verdict can't be blank"
      )

      click_button("Save and come back later")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "In progress"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Site description")) do
        choose("Edit to accept")
      end

      click_button("Save and come back later")

      expect(page).to have_content("Site description entry can't be blank")

      within(find("fieldset", text: "Site description")) do
        fill_in("Update site description", with: "edited site description")
      end

      click_button("Save and come back later")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "In progress"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Consultation")) do
        choose("Return to officer with comment")
      end

      click_button("Save and come back later")

      expect(page).to have_content(
        "Consultation summary comment text can't be blank"
      )

      within(find("fieldset", text: "Consultation")) do
        fill_in(
          "Explain to the assessor why this needs reviewing",
          with: "consultation comment"
        )
      end

      click_button("Save and come back later")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "In progress"
      )

      click_link("Review assessment summaries")

      within(find("fieldset", text: "Additional evidence")) do
        choose("Accept")
      end

      click_button("Save and mark as complete")

      expect(page).to have_list_item_for(
        "Review assessment summaries", with: "Checked"
      )
    end
  end
end
