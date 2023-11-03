# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing assessment summaries" do
  let(:local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority:,
      name: "Alice Smith"
    )
  end

  let!(:reviewer) do
    create(
      :user,
      :reviewer,
      local_authority:,
      name: "Bella Jones"
    )
  end

  let!(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      :prior_approval,
      local_authority:,
      decision: :granted
    )
  end

  let!(:consultation) do
    planning_application.consultation
  end

  before do
    create(
      :recommendation,
      planning_application:,
      created_at: Time.zone.local(2022, 11, 27, 12, 30)
    )

    sign_in(reviewer)
  end

  context "when planning application is a prior approval" do
    context "when assessor filled out summaries" do
      before do
        create(
          :assessment_detail,
          :summary_of_work,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "summary of works"
        )

        create(
          :assessment_detail,
          :amenity,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "assessment of amenity"
        )

        create(
          :assessment_detail,
          :site_description,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "site description"
        )

        ## Created a second to show that previous summaries works
        create(
          :assessment_detail,
          :site_description,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "site description"
        )

        create(
          :assessment_detail,
          :additional_evidence,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "additional evidence"
        )

        create(
          :assessment_detail,
          :publicity_summary,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "publicity summary"
        )

        create(
          :assessment_detail,
          :past_applications,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "past applications"
        )
      end

      let!(:neighbour1) { create(:neighbour, address: "1 Cookie Avenue", consultation:) }
      let!(:neighbour2) { create(:neighbour, address: "2 Cookie Avenue", consultation:) }
      let!(:neighbour3) { create(:neighbour, address: "3 Cookie Avenue", consultation:) }
      let!(:objection_response) { create(:neighbour_response, neighbour: neighbour1, summary_tag: "objection") }
      let!(:supportive_response1) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
      let!(:supportive_response2) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
      let!(:neutral_response) { create(:neighbour_response, neighbour: neighbour2, summary_tag: "neutral") }

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
          expect(find(".govuk-tag")).to have_content("Completed")

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
          "Amenity reviewer verdict can't be blank"
        )

        expect(page).to have_content(
          "Publicity summary reviewer verdict can't be blank"
        )

        expect(page).to have_content(
          "Past applications reviewer verdict can't be blank"
        )

        click_button("Save and come back later")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "In progress"
        )

        click_link("Review assessment summaries")

        within(find("fieldset", text: "Site description")) do
          expect(page).to have_link(
            "View site on Google Maps",
            href: "https://google.co.uk/maps/place/#{CGI.escape(planning_application.full_address)}"
          )
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

        within("ul#review-assessment-section") do
          expect(page).to have_list_item_for(
            "Review assessment summaries", with: "In progress"
          )
        end

        click_link("Review assessment summaries")

        within(find("fieldset", text: "Summary of additional evidence")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Amenity assessment")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of neighbour responses")) do
          expect(page).to have_link(
            "View neighbour responses",
            href: new_planning_application_consultation_neighbour_response_path(planning_application)
          )

          expect(page).to have_content("View neighbour responses: There is 1 neutral, 1 objection, 2 supportive.")

          choose("Accept")
        end

        within(find("fieldset", text: "Summary of relevant historical applications")) do
          choose("Accept")
        end

        click_button("Save and mark as complete")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "Checked"
        )

        click_link("Sign-off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "recommendation challenged"
        )

        click_button("Save and mark as complete")
        click_link("Review assessment summaries")

        click_link("Log out")
        sign_in(assessor)
        visit(planning_application_path(planning_application))

        expect(page).to have_list_item_for(
          "Check and assess", with: "To be reviewed"
        )

        click_link("Check and assess")
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")
        click_link("Log out")
        sign_in(reviewer)
        visit(planning_application_path(planning_application))

        click_link("Review and sign-off")
        click_link("Sign-off recommendation")
        choose("Yes")
        click_button("Save and mark as complete")
        click_link("Review assessment summaries")
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
          "Past applications reviewer verdict can't be blank"
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

        within(find("fieldset", text: "Summary of additional evidence")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of neighbour responses")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Amenity assessment")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of relevant historical applications")) do
          choose("Accept")
        end

        click_button("Save and mark as complete")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "Checked"
        )
      end
    end
  end

  context "when planning application is an LDC" do
    before do
      ldc = create(:application_type)
      planning_application.update(application_type: ldc)
    end

    context "when assessor filled out summaries" do
      before do
        create(
          :assessment_detail,
          :summary_of_work,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "summary of works"
        )

        create(
          :assessment_detail,
          :site_description,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "site description"
        )

        ## Created a second to show that previous summaries works
        create(
          :assessment_detail,
          :site_description,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "site description"
        )

        create(:consultee, consultation:)

        create(
          :assessment_detail,
          :consultation_summary,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "consultation summary",
          created_at: Time.zone.local(2022, 11, 27, 12, 15)
        )

        create(
          :assessment_detail,
          :additional_evidence,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "additional evidence"
        )

        create(
          :assessment_detail,
          :past_applications,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "past applications"
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
          expect(find(".govuk-tag")).to have_content("Completed")

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

        expect(page).to have_content(
          "Past applications reviewer verdict can't be blank"
        )

        expect(page).not_to have_content(
          "Amenity assessment reviewer verdict can't be blank"
        )

        expect(page).not_to have_content(
          "Summary of neighbour responses reviewer verdict can't be blank"
        )

        click_button("Save and come back later")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "In progress"
        )

        click_link("Review assessment summaries")

        within(find("fieldset", text: "Site description")) do
          expect(page).to have_link(
            "View site on Google Maps",
            href: "https://google.co.uk/maps/place/#{CGI.escape(planning_application.full_address)}"
          )
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

        within("ul#review-assessment-section") do
          expect(page).to have_list_item_for(
            "Review assessment summaries", with: "In progress"
          )
        end

        click_link("Review assessment summaries")

        within(find("fieldset", text: "Summary of additional evidence")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of relevant historical applications")) do
          choose("Accept")
        end

        click_button("Save and mark as complete")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "Checked"
        )

        click_link("Sign-off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "recommendation challenged"
        )

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
          "Summary of consultation", with: "Completed"
        )

        click_link("Application")

        click_link("Check and assess")
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
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
          expect(find(".govuk-tag")).to have_content("Completed")
        end

        click_link("Review")
        click_link("Sign-off recommendation")
        choose("Yes")
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
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "recommendation challenged again"
        )

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

        expect(page).to have_content(
          "Past applications reviewer verdict can't be blank"
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

        within(find("fieldset", text: "Summary of additional evidence")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of relevant historical applications")) do
          choose("Accept")
        end

        click_button("Save and mark as complete")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "Checked"
        )
      end
    end
  end

  context "when planning application is planning permission" do
    before do
      planning_permission = create(:application_type, :planning_permission)
      planning_application.update(application_type: planning_permission)
    end

    context "when assessor filled out summaries" do
      before do
        create(
          :assessment_detail,
          :summary_of_work,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "summary of works"
        )

        create(
          :assessment_detail,
          :site_description,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "site description"
        )

        create(
          :assessment_detail,
          :additional_evidence,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "additional evidence"
        )

        create(
          :assessment_detail,
          :additional_evidence,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "public summary"
        )

        create(
          :assessment_detail,
          :consultation_summary,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "consultation summary"
        )

        create(
          :assessment_detail,
          :publicity_summary,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "publicity summary"
        )

        create(
          :assessment_detail,
          :past_applications,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "past applications"
        )
      end

      let!(:neighbour1) { create(:neighbour, address: "1 Cookie Avenue", consultation:) }
      let!(:neighbour2) { create(:neighbour, address: "2 Cookie Avenue", consultation:) }
      let!(:neighbour3) { create(:neighbour, address: "3 Cookie Avenue", consultation:) }
      let!(:objection_response) { create(:neighbour_response, neighbour: neighbour1, summary_tag: "objection") }
      let!(:supportive_response1) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
      let!(:supportive_response2) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
      let!(:neutral_response) { create(:neighbour_response, neighbour: neighbour2, summary_tag: "neutral") }

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
          expect(find(".govuk-tag")).to have_content("Completed")

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
          "Publicity summary reviewer verdict can't be blank"
        )

        expect(page).to have_content(
          "Consultation summary reviewer verdict can't be blank"
        )

        expect(page).to have_content(
          "Past applications reviewer verdict can't be blank"
        )

        click_button("Save and come back later")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "In progress"
        )

        click_link("Review assessment summaries")

        within(find("fieldset", text: "Site description")) do
          expect(page).to have_link(
            "View site on Google Maps",
            href: "https://google.co.uk/maps/place/#{CGI.escape(planning_application.full_address)}"
          )
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

        within("ul#review-assessment-section") do
          expect(page).to have_list_item_for(
            "Review assessment summaries", with: "In progress"
          )
        end

        click_link("Review assessment summaries")

        within(find("fieldset", text: "Summary of additional evidence")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of neighbour responses")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Consultation")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of relevant historical applications")) do
          choose("Accept")
        end

        click_button("Save and mark as complete")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "Checked"
        )

        click_link("Sign-off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "recommendation challenged"
        )

        click_button("Save and mark as complete")
        click_link("Review assessment summaries")

        click_link("Log out")
        sign_in(assessor)
        visit(planning_application_path(planning_application))

        expect(page).to have_list_item_for(
          "Check and assess", with: "To be reviewed"
        )

        click_link("Check and assess")
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")
        click_link("Log out")
        sign_in(reviewer)
        visit(planning_application_path(planning_application))

        click_link("Review and sign-off")
        click_link("Sign-off recommendation")
        choose("Yes")
        click_button("Save and mark as complete")
        click_link("Review assessment summaries")
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
          "Publicity summary reviewer verdict can't be blank"
        )

        expect(page).to have_content(
          "Consultation summary reviewer verdict can't be blank"
        )

        expect(page).to have_content(
          "Past applications reviewer verdict can't be blank"
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

        within(find("fieldset", text: "Summary of additional evidence")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of neighbour responses")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Consultation")) do
          choose("Accept")
        end

        within(find("fieldset", text: "Summary of relevant historical applications")) do
          choose("Accept")
        end

        click_button("Save and mark as complete")

        expect(page).to have_list_item_for(
          "Review assessment summaries", with: "Checked"
        )
      end
    end
  end
end
