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

  context "when assessor has filled out the assessment summaries" do
    before do
      create(:decision, :pa_granted)
      create(:decision, :pa_not_required)
      create(:decision, :pa_refused)
    end

    let!(:neighbour_summary) {
      travel_to(Time.zone.local(2024, 11, 28, 11, 30)) do
        create(
          :assessment_detail,
          :neighbour_summary,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "neighbour summary"
        )
      end
    }

    let!(:summary_of_work) {
      travel_to(Time.zone.local(2024, 11, 28, 11, 30)) do
        create(:assessment_detail,
          :summary_of_work,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "summary of works assessment")
      end
    }

    let!(:site_description) {
      travel_to(Time.zone.local(2024, 11, 28, 11, 30)) do
        create(
          :assessment_detail,
          :site_description,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "site description"
        )
      end
    }

    let!(:consultation_summary) {
      travel_to(Time.zone.local(2024, 11, 28, 11, 30)) do
        create(
          :assessment_detail,
          :consultation_summary,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "consultation summary"
        )
      end
    }

    let!(:additional_evidence) {
      travel_to(Time.zone.local(2024, 11, 28, 11, 30)) do
        create(
          :assessment_detail,
          :additional_evidence,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "additional evidence"
        )
      end
    }
    let!(:amenity) {
      travel_to(Time.zone.local(2024, 11, 28, 11, 30)) do
        create(
          :assessment_detail,
          :amenity,
          assessment_status: :complete,
          planning_application:,
          user: assessor,
          entry: "assessment of amenity"
        )
      end
    }

    let!(:neighbour1) { create(:neighbour, address: "1, Cookie Avenue, AAA111", consultation:) }
    let!(:neighbour2) { create(:neighbour, address: "2, Cookie Avenue, AAA111", consultation:) }
    let!(:neighbour3) { create(:neighbour, address: "3, Cookie Avenue, AAA111", consultation:) }
    let!(:objection_response) { create(:neighbour_response, neighbour: neighbour1, summary_tag: "objection") }
    let!(:supportive_response1) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
    let!(:supportive_response2) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
    let!(:neutral_response) { create(:neighbour_response, neighbour: neighbour2, summary_tag: "neutral") }

    it "shows validation errors when returning without comments" do
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
      expect(page).to have_selector("h2.bops-task-accordion-heading", text: "Review assessment summaries")

      # Neighbour summary
      click_button "Summary of neighbour responses"
      within("#neighbour_summary_footer") do
        click_button("Save and mark as complete")
      end
      expect(page).to have_selector("[role=alert] li", text: "Determine whether this is correct")
      within("#neighbour_summary_section") do
        expect(find("button")[:"aria-expanded"]).to eq("true")
      end
      within("#neighbour_summary_footer") do
        expect(page).to have_selector("p.govuk-error-message", text: "Determine whether this is correct")
      end

      within("#neighbour_summary_footer") do
        choose "Return with comments"
        click_button("Save and mark as complete")
      end

      expect(page).to have_selector("[role=alert] li", text: "You must add a comment")
      within("#neighbour_summary_section") do
        expect(find("button")[:"aria-expanded"]).to eq("true")
      end
      within("#neighbour_summary_footer") do
        expect(page).to have_selector("p.govuk-error-message", text: "You must add a comment")
      end

      # Summary of works
      click_button "Summary of works"
      within("#summary_of_work_footer") do
        choose "Return with comments"
        click_button("Save and mark as complete")
      end

      expect(page).to have_selector("[role=alert] li", text: "You must add a comment")
      within("#summary_of_work_section") do
        expect(find("button")[:"aria-expanded"]).to eq("true")
      end
      within("#summary_of_work_footer") do
        expect(page).to have_selector("p.govuk-error-message", text: "You must add a comment")
      end

      # Consultation
      click_button "Consultation"
      within("#consultation_summary_footer") do
        choose "Return with comments"
        click_button("Save and mark as complete")
      end

      expect(page).to have_selector("[role=alert] li", text: "You must add a comment")
      within("#consultation_summary_section") do
        expect(find("button")[:"aria-expanded"]).to eq("true")
      end
      within("#consultation_summary_footer") do
        expect(page).to have_selector("p.govuk-error-message", text: "You must add a comment")
      end

      # Site description
      click_button "Site description"
      within("#site_description_footer") do
        choose "Return with comments"
        click_button("Save and mark as complete")
      end

      expect(page).to have_selector("[role=alert] li", text: "You must add a comment")
      within("#site_description_section") do
        expect(find("button")[:"aria-expanded"]).to eq("true")
      end
      within("#site_description_footer") do
        expect(page).to have_selector("p.govuk-error-message", text: "You must add a comment")
      end

      # Additional evidence
      click_button "Summary of additional evidence"
      within("#additional_evidence_footer") do
        choose "Return with comments"
        click_button("Save and mark as complete")
      end

      expect(page).to have_selector("[role=alert] li", text: "You must add a comment")
      within("#additional_evidence_section") do
        expect(find("button")[:"aria-expanded"]).to eq("true")
      end
      within("#additional_evidence_footer") do
        expect(page).to have_selector("p.govuk-error-message", text: "You must add a comment")
      end

      # Amenity
      click_button "Amenity"
      within("#amenity_footer") do
        choose "Return with comments"
        click_button("Save and mark as complete")
      end

      expect(page).to have_selector("[role=alert] li", text: "You must add a comment")
      within("#amenity_section") do
        expect(find("button")[:"aria-expanded"]).to eq("true")
      end
      within("#amenity_footer") do
        expect(page).to have_selector("p.govuk-error-message", text: "You must add a comment")
      end
    end

    context "when reviewer submits their review" do
      before do
        travel_to(Time.zone.local(2024, 11, 28, 12, 30))
        visit "/planning_applications/#{planning_application.reference}/review/tasks"
      end

      it "summary of neighbour responses" do
        click_button "Summary of neighbour responses"
        within("#neighbour_summary_section") do
          expect(find(".govuk-tag")).to have_content("Not started")

          within("#neighbour_summary_block") do
            expect(page).to have_link("View neighbour responses")
            expect(page).to have_content("There is 1 neutral, 1 objection, 2 supportive.")
            expect(page).to have_content("neighbour summary")
            expect(page).to have_link(
              "Edit",
              href: "/planning_applications/#{planning_application.reference}/assessment/assessment_details/#{neighbour_summary.id}/edit?category=neighbour_summary"
            )
          end
        end

        within("#neighbour_summary_footer") do
          choose "Agree"
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of neighbour summary was successfully updated")

        within("#neighbour_summary_footer") do
          expect(page).to have_checked_field("Accept")
        end

        within("#neighbour_summary_footer") do
          choose "Return with comments"

          fill_in(
            "Add a comment",
            with: "Summary is wrong"
          )
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of neighbour summary was successfully updated")
        click_link("Sign off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "Recommendation challenged"
        )
        click_button("Save and mark as complete")
        within("#neighbour_summary_section") do
          expect(find(".govuk-tag")).to have_content("Awaiting changes")
        end

        sign_out(reviewer)
        travel 1.day
        sign_in(assessor)
        visit "/planning_applications/#{planning_application.reference}"

        expect(page).to have_list_item_for(
          "Check and assess", with: "To be reviewed"
        )
        click_link("Check and assess")
        expect(page).to have_list_item_for(
          "Summary of neighbour responses", with: "To be reviewed"
        )
        click_link("Summary of neighbour responses")

        within(".comment-component") do
          expect(page).to have_content("Reviewer comment")
          expect(page).to have_content("Sent on 28 November 2024 12:30 by Bella Jones")
          expect(page).to have_content("Summary is wrong")
        end
        fill_in(
          "Summary of untagged comments",
          with: "A new summary"
        )

        click_button("Save and mark as complete")
        expect(page).to have_content("Summary of neighbour responses was successfully updated.")
        expect(page).to have_list_item_for(
          "Summary of neighbour responses", with: "Completed"
        )
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")
        sign_out(assessor)
        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.reference}"

        click_link("Review and sign-off")

        within("#neighbour_summary_section") do
          expect(find(".govuk-tag")).to have_content("Updated")

          within("#neighbour_summary_block") do
            find("span", text: "See previous summaries").click
            expect(page).to have_content("Bella Jones marked this for review 28 November 2024 12:30")
            expect(page).to have_content("Summary is wrong")
            expect(page).to have_content("Alice Smith created neighbour summary 28 November 2024 11:30")
            expect(page).to have_content("Untagged: A new summary")
          end
          within("#neighbour_summary_footer") do
            choose "Agree"
            click_button("Save and mark as complete")
          end
        end

        within("#neighbour_summary_section") do
          expect(find(".govuk-tag")).to have_content("Completed")
        end

        click_link("Sign off recommendation")
        choose("Yes")
        click_button("Save and mark as complete")

        expect(page).to have_content("Recommendation was successfully reviewed")
      end

      it "summary of works" do
        click_button "Summary of works"
        within("#summary_of_work_section") do
          expect(find(".govuk-tag")).to have_content("Not started")

          within("#summary_of_work_block") do
            expect(page).to have_content("summary of works assessment")
            expect(page).to have_link(
              "Edit",
              href: "/planning_applications/#{planning_application.reference}/assessment/assessment_details/#{summary_of_work.id}/edit?category=summary_of_work"
            )
          end
        end

        within("#summary_of_work_footer") do
          choose "Agree"
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of summary of work was successfully updated")

        within("#summary_of_work_footer") do
          expect(page).to have_checked_field("Accept")
        end

        within("#summary_of_work_footer") do
          choose "Return with comments"

          fill_in(
            "Add a comment",
            with: "Summary is wrong"
          )
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of summary of work was successfully updated")
        click_link("Sign off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "Recommendation challenged"
        )
        click_button("Save and mark as complete")
        within("#summary_of_work_section") do
          expect(find(".govuk-tag")).to have_content("Awaiting changes")
        end

        sign_out(reviewer)
        travel 1.day
        sign_in(assessor)
        visit "/planning_applications/#{planning_application.reference}"

        expect(page).to have_list_item_for(
          "Check and assess", with: "To be reviewed"
        )
        click_link("Check and assess")
        within "#main-content" do
          expect(page).to have_list_item_for("Summary of works", with: "To be reviewed")
          click_link("Summary of works")
        end

        within(".comment-component") do
          expect(page).to have_content("Reviewer comment")
          expect(page).to have_content("Sent on 28 November 2024 12:30 by Bella Jones")
          expect(page).to have_content("Summary is wrong")
        end
        fill_in(
          "assessment_detail[entry]",
          with: "A new summary"
        )

        click_button("Save and mark as complete")
        expect(page).to have_content("Summary of works was successfully updated.")
        within "#main-content" do
          expect(page).to have_list_item_for("Summary of works", with: "Completed")
        end
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")
        sign_out(assessor)
        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.reference}"

        click_link("Review and sign-off")

        within("#summary_of_work_section") do
          expect(find(".govuk-tag")).to have_content("Updated")

          within("#summary_of_work_block") do
            find("span", text: "See previous summaries").click
            expect(page).to have_content("Bella Jones marked this for review 28 November 2024 12:30")
            expect(page).to have_content("Summary is wrong")
            expect(page).to have_content("Alice Smith created summary of works 28 November 2024 11:30")
            expect(page).to have_content("A new summary")
          end
          within("#summary_of_work_footer") do
            choose "Agree"
            click_button("Save and mark as complete")
          end
        end

        within("#summary_of_work_section") do
          expect(find(".govuk-tag")).to have_content("Completed")
        end

        click_link("Sign off recommendation")
        choose("Yes")
        click_button("Save and mark as complete")

        expect(page).to have_content("Recommendation was successfully reviewed")
      end

      it "site description" do
        click_button "Site description"
        within("#site_description_section") do
          expect(find(".govuk-tag")).to have_content("Not started")

          within("#site_description_block") do
            expect(page).to have_content("site description")
            expect(page).to have_link("View site on Google Maps (opens in new tab)")
            expect(page).to have_link(
              "Edit",
              href: "/planning_applications/#{planning_application.reference}/assessment/assessment_details/#{site_description.id}/edit?category=site_description"
            )
          end
        end

        within("#site_description_footer") do
          choose "Agree"
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of site description was successfully updated")

        within("#site_description_footer") do
          expect(page).to have_checked_field("Accept")
        end

        within("#site_description_footer") do
          choose "Return with comments"

          fill_in(
            "Add a comment",
            with: "Summary is wrong"
          )
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of site description was successfully updated")
        click_link("Sign off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "Recommendation challenged"
        )
        click_button("Save and mark as complete")
        within("#site_description_section") do
          expect(find(".govuk-tag")).to have_content("Awaiting changes")
        end

        sign_out(reviewer)
        travel 1.day
        sign_in(assessor)
        visit "/planning_applications/#{planning_application.reference}"

        expect(page).to have_list_item_for(
          "Check and assess", with: "To be reviewed"
        )
        click_link("Check and assess")
        within "#main-content" do
          expect(page).to have_list_item_for(
            "Site description", with: "To be reviewed"
          )
          click_link("Site description")
        end

        within(".comment-component") do
          expect(page).to have_content("Reviewer comment")
          expect(page).to have_content("Sent on 28 November 2024 12:30 by Bella Jones")
          expect(page).to have_content("Summary is wrong")
        end
        fill_in(
          "assessment_detail[entry]",
          with: "A new summary"
        )

        click_button("Save and mark as complete")
        expect(page).to have_content("Site description was successfully updated.")
        within "#main-content" do
          expect(page).to have_list_item_for(
            "Site description", with: "Completed"
          )
        end
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")
        sign_out(assessor)
        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.reference}"

        click_link("Review and sign-off")

        within("#site_description_section") do
          expect(find(".govuk-tag")).to have_content("Updated")

          within("#site_description_block") do
            find("span", text: "See previous summaries").click
            expect(page).to have_content("Bella Jones marked this for review 28 November 2024 12:30")
            expect(page).to have_content("Summary is wrong")
            expect(page).to have_content("Alice Smith created site description 28 November 2024 11:30")
            expect(page).to have_content("A new summary")
          end
          within("#site_description_footer") do
            choose "Agree"
            click_button("Save and mark as complete")
          end
        end

        within("#site_description_section") do
          expect(find(".govuk-tag")).to have_content("Completed")
        end

        click_link("Sign off recommendation")
        choose("Yes")
        click_button("Save and mark as complete")

        expect(page).to have_content("Recommendation was successfully reviewed")
      end

      it "summary of consultation" do
        planning_application.application_type.assessment_details << "consultation_summary"
        planning_application.application_type.save

        click_button "Consultation"
        within("#consultation_summary_section") do
          expect(find(".govuk-tag")).to have_content("Not started")

          within("#consultation_summary_block") do
            expect(page).to have_content("consultation summary")
            expect(page).to have_link(
              "Edit",
              href: "/planning_applications/#{planning_application.reference}/assessment/assessment_details/#{consultation_summary.id}/edit?category=consultation_summary"
            )
          end
        end

        within("#consultation_summary_footer") do
          choose "Agree"
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of consultation summary was successfully updated")

        within("#consultation_summary_footer") do
          expect(page).to have_checked_field("Accept")
        end

        within("#consultation_summary_footer") do
          choose "Return with comments"

          fill_in(
            "Add a comment",
            with: "Summary is wrong"
          )
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of consultation summary was successfully updated")
        click_link("Sign off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "Recommendation challenged"
        )
        click_button("Save and mark as complete")
        within("#consultation_summary_section") do
          expect(find(".govuk-tag")).to have_content("Awaiting changes")
        end

        sign_out(reviewer)
        travel 1.day
        sign_in(assessor)
        visit "/planning_applications/#{planning_application.reference}"

        expect(page).to have_list_item_for(
          "Check and assess", with: "To be reviewed"
        )
        click_link("Check and assess")
        within "#main-content" do
          expect(page).to have_list_item_for(
            "Summary of consultation", with: "To be reviewed"
          )
          click_link("Summary of consultation")
        end

        within(".comment-component") do
          expect(page).to have_content("Reviewer comment")
          expect(page).to have_content("Sent on 28 November 2024 12:30 by Bella Jones")
          expect(page).to have_content("Summary is wrong")
        end
        fill_in(
          "assessment_detail[entry]",
          with: "A new summary"
        )

        click_button("Save and mark as complete")
        expect(page).to have_content("Consultation summary successfully updated.")
        within "#main-content" do
          expect(page).to have_list_item_for(
            "Summary of consultation", with: "Completed"
          )
        end
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")
        sign_out(assessor)
        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.reference}"

        click_link("Review and sign-off")

        within("#consultation_summary_section") do
          expect(find(".govuk-tag")).to have_content("Updated")

          within("#consultation_summary_block") do
            find("span", text: "See previous summaries").click
            expect(page).to have_content("Bella Jones marked this for review 28 November 2024 12:30")
            expect(page).to have_content("Summary is wrong")
            expect(page).to have_content("Alice Smith created consultation summary 28 November 2024 11:30")
            expect(page).to have_content("A new summary")
          end
          within("#consultation_summary_footer") do
            choose "Agree"
            click_button("Save and mark as complete")
          end
        end

        within("#consultation_summary_section") do
          expect(find(".govuk-tag")).to have_content("Completed")
        end

        click_link("Sign off recommendation")
        choose("Yes")
        click_button("Save and mark as complete")

        expect(page).to have_content("Recommendation was successfully reviewed")
      end

      it "summary of additional evidence" do
        click_button "Summary of additional evidence"
        within("#additional_evidence_section") do
          expect(find(".govuk-tag")).to have_content("Not started")

          within("#additional_evidence_block") do
            expect(page).to have_content("additional evidence")
            expect(page).to have_link(
              "Edit",
              href: "/planning_applications/#{planning_application.reference}/assessment/assessment_details/#{additional_evidence.id}/edit?category=additional_evidence"
            )
          end
        end

        within("#additional_evidence_footer") do
          choose "Agree"
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of additional evidence was successfully updated")

        within("#additional_evidence_footer") do
          expect(page).to have_checked_field("Accept")
        end

        within("#additional_evidence_footer") do
          choose "Return with comments"

          fill_in(
            "Add a comment",
            with: "Summary is wrong"
          )
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of additional evidence was successfully updated")
        click_link("Sign off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "Recommendation challenged"
        )
        click_button("Save and mark as complete")
        within("#additional_evidence_section") do
          expect(find(".govuk-tag")).to have_content("Awaiting changes")
        end

        sign_out(reviewer)
        travel 1.day
        sign_in(assessor)
        visit "/planning_applications/#{planning_application.reference}"

        expect(page).to have_list_item_for(
          "Check and assess", with: "To be reviewed"
        )
        click_link("Check and assess")
        expect(page).to have_list_item_for(
          "Summary of additional evidence", with: "To be reviewed"
        )
        click_link("Summary of additional evidence")

        within(".comment-component") do
          expect(page).to have_content("Reviewer comment")
          expect(page).to have_content("Sent on 28 November 2024 12:30 by Bella Jones")
          expect(page).to have_content("Summary is wrong")
        end
        fill_in(
          "assessment_detail[entry]",
          with: "A new summary"
        )

        click_button("Save and mark as complete")
        expect(page).to have_content("Additional evidence was successfully updated.")
        expect(page).to have_list_item_for(
          "Summary of additional evidence", with: "Completed"
        )
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")
        sign_out(assessor)
        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.reference}"

        click_link("Review and sign-off")

        within("#additional_evidence_section") do
          expect(find(".govuk-tag")).to have_content("Updated")

          within("#additional_evidence_block") do
            find("span", text: "See previous summaries").click
            expect(page).to have_content("Bella Jones marked this for review 28 November 2024 12:30")
            expect(page).to have_content("Summary is wrong")
            expect(page).to have_content("Alice Smith created additional evidence 28 November 2024 11:30")
            expect(page).to have_content("A new summary")
          end
          within("#additional_evidence_footer") do
            choose "Agree"
            click_button("Save and mark as complete")
          end
        end

        within("#additional_evidence_section") do
          expect(find(".govuk-tag")).to have_content("Completed")
        end

        click_link("Sign off recommendation")
        choose("Yes")
        click_button("Save and mark as complete")

        expect(page).to have_content("Recommendation was successfully reviewed")
      end

      it "amenity" do
        click_button "Amenity assessment"
        within("#amenity_section") do
          expect(find(".govuk-tag")).to have_content("Not started")

          within("#amenity_block") do
            expect(page).to have_content("amenity")
            expect(page).to have_link(
              "Edit",
              href: "/planning_applications/#{planning_application.reference}/assessment/assessment_details/#{amenity.id}/edit?category=amenity"
            )
          end
        end

        within("#amenity_footer") do
          choose "Agree"
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of amenity was successfully updated")

        within("#amenity_footer") do
          expect(page).to have_checked_field("Accept")
        end

        within("#amenity_footer") do
          choose "Return with comments"

          fill_in(
            "Add a comment",
            with: "Summary is wrong"
          )
          click_button("Save and mark as complete")
        end

        expect(page).to have_content("Review of amenity was successfully updated")
        click_link("Sign off recommendation")
        choose("No (return the case for assessment)")

        fill_in(
          "Explain to the officer why the case is being returned",
          with: "Recommendation challenged"
        )
        click_button("Save and mark as complete")
        within("#amenity_section") do
          expect(find(".govuk-tag")).to have_content("Awaiting changes")
        end

        sign_out(reviewer)
        travel 1.day
        sign_in(assessor)
        visit "/planning_applications/#{planning_application.reference}"

        expect(page).to have_list_item_for(
          "Check and assess", with: "To be reviewed"
        )
        click_link("Check and assess")
        expect(page).to have_list_item_for(
          "Amenity", with: "To be reviewed"
        )
        click_link("Amenity")

        within(".comment-component") do
          expect(page).to have_content("Reviewer comment")
          expect(page).to have_content("Sent on 28 November 2024 12:30 by Bella Jones")
          expect(page).to have_content("Summary is wrong")
        end
        fill_in(
          "assessment_detail[entry]",
          with: "A new summary"
        )

        click_button("Save and mark as complete")
        expect(page).to have_content("Amenity assessment was successfully updated.")
        expect(page).to have_list_item_for(
          "Amenity", with: "Completed"
        )
        click_link("Make draft recommendation")

        click_button("Update assessment")
        click_link("Review and submit recommendation")
        click_button("Submit recommendation")
        sign_out(assessor)
        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.reference}"

        click_link("Review and sign-off")

        within("#amenity_section") do
          expect(find(".govuk-tag")).to have_content("Updated")

          within("#amenity_block") do
            find("span", text: "See previous summaries").click
            expect(page).to have_content("Bella Jones marked this for review 28 November 2024 12:30")
            expect(page).to have_content("Summary is wrong")
            expect(page).to have_content("Alice Smith created amenity assessment 28 November 2024 11:30")
            expect(page).to have_content("A new summary")
          end
          within("#amenity_footer") do
            choose "Agree"
            click_button("Save and mark as complete")
          end
        end

        within("#amenity_section") do
          expect(find(".govuk-tag")).to have_content("Completed")
        end

        click_link("Sign off recommendation")
        choose("Yes")
        click_button("Save and mark as complete")

        expect(page).to have_content("Recommendation was successfully reviewed")
      end
    end
  end
end
