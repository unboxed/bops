# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Press notice" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let!(:planning_application) do
    create(:planning_application, :prior_approval, local_authority:)
  end

  before do
    sign_in assessor

    visit planning_application_path(planning_application)
  end

  describe "responding to whether a press notice is required" do
    before { travel_to(Time.zone.local(2023, 3, 15, 12)) }

    it "shows the press notice item in the tasklist" do
      click_link "Consultees, neighbours and publicity"

      within("#publicity-section") do
        expect(page).to have_css("#press-notice")
        expect(page).to have_link("Press notice")
        expect(page).to have_content("Not started")
      end
    end

    it "I can see the relevant information on the press notice page" do
      click_link "Consultees, neighbours and publicity"
      click_link "Press notice"

      within("#planning-application-details") do
        expect(page).to have_content("Press notice")
        expect(page).to have_content(planning_application.reference)
        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content(planning_application.description)
      end

      expect(page).to have_content("Does this application require a press notice?")
      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Press notice")
      end
    end

    context "when a press notice is required" do
      it "I get an error when not providing a reason" do
        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"

        choose("Yes")
        click_button("Save and mark as complete")

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
          expect(page).to have_content("You must provide a reason for the press notice")
        end
      end

      it "I provide reasons why a press notice is required" do
        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"

        choose("Yes")
        check("The application is for a Major Development")
        check("An environmental statement accompanies this application")

        click_button("Save and mark as complete")
        expect(page).to have_content("Press notice response has been successfully added")

        within("#publicity-section") do
          expect(page).to have_content("Completed")
          click_link("Press notice")
        end

        expect(find_by_id("press-notice-required-true-field")).to be_checked
        expect(find_by_id("press_notice_reason_major_development")).to be_checked
        expect(find_by_id("press_notice_reason_environment")).to be_checked

        expect(PressNotice.last).to have_attributes(
          planning_application_id: planning_application.id,
          required: true,
          reasons: {
            "environment" => "An environmental statement accompanies this application",
            "major_development" => "The application is for a Major Development"
          },
          requested_at: Time.zone.local(2023, 3, 15, 12)
        )

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice",
          audit_comment: "Press notice has been marked as required with the following reasons: The application is for a Major Development, An environmental statement accompanies this application",
          user: assessor
        )

        visit planning_application_audits_path(planning_application)
        within("#audit_#{Audit.last.id}") do
          expect(page).to have_content("Press notice response added")
          expect(page).to have_content(assessor.name)
          expect(page).to have_content("Press notice has been marked as required with the following reasons: The application is for a Major Development, An environmental statement accompanies this application")
          expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end

      it "I provide a standard reason and an other reason why a press notice is required" do
        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"

        choose("Yes")
        check("The application is for a Major Development")
        check("Other")
        fill_in(
          "Provide an other reason why this application requires a press notice",
          with: "An other reason not included in the list"
        )

        click_button("Save and mark as complete")
        click_link("Press notice")

        expect(find_by_id("press-notice-required-true-field")).to be_checked
        expect(find_by_id("press_notice_reason_major_development")).to be_checked
        expect(find_by_id("press-notice-other-reason-selected-1-field")).to be_checked

        expect(PressNotice.last).to have_attributes(
          planning_application_id: planning_application.id,
          required: true,
          reasons: {
            "other" => "An other reason not included in the list",
            "major_development" => "The application is for a Major Development"
          },
          requested_at: Time.zone.local(2023, 3, 15, 12)
        )

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice",
          audit_comment: "Press notice has been marked as required with the following reasons: The application is for a Major Development, An other reason not included in the list",
          user: assessor
        )
      end

      it "I provide an other reason why a press notice is required" do
        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"

        choose("Yes")
        check("Other")
        fill_in(
          "Provide an other reason why this application requires a press notice",
          with: "An other reason not included in the list"
        )

        click_button("Save and mark as complete")
        click_link("Press notice")

        expect(find_by_id("press-notice-required-true-field")).to be_checked
        expect(find_by_id("press-notice-other-reason-selected-1-field")).to be_checked

        expect(PressNotice.last).to have_attributes(
          planning_application_id: planning_application.id,
          required: true,
          reasons: {
            "other" => "An other reason not included in the list"
          },
          requested_at: Time.zone.local(2023, 3, 15, 12)
        )

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice",
          audit_comment: "Press notice has been marked as required with the following reasons: An other reason not included in the list",
          user: assessor
        )
      end
    end

    context "when a press notice is not required" do
      it "I can mark it as not required" do
        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"

        choose("No")

        click_button("Save and mark as complete")
        expect(page).to have_content("Press notice response has been successfully added")
        within("#publicity-section") do
          expect(page).to have_content("Completed")
          click_link("Press notice")
        end

        expect(find_by_id("press-notice-required-field")).to be_checked

        expect(PressNotice.last).to have_attributes(
          planning_application_id: planning_application.id,
          required: false,
          reasons: {},
          requested_at: nil
        )

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice",
          audit_comment: "Press notice has been marked as not required",
          user: assessor
        )
      end
    end

    context "when editing a press notice" do
      context "when press notice has been marked as required" do
        let!(:press_notice) { create(:press_notice, :with_other_reason, planning_application:, requested_at: Time.zone.local(2023, 3, 14, 12)) }

        it "I can mark a press notice as not required after it was marked as required" do
          click_link "Consultees, neighbours and publicity"
          click_link "Press notice"

          choose("No")

          click_button("Save and mark as complete")
          click_link("Press notice")

          expect(find_by_id("press-notice-required-field")).to be_checked

          expect(PressNotice.last).to have_attributes(
            planning_application_id: planning_application.id,
            required: false,
            reasons: {},
            requested_at: Time.zone.local(2023, 3, 14, 12)
          )

          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "press_notice",
            audit_comment: "Press notice has been marked as not required",
            user: assessor
          )
        end

        it "I can modify the reasons to why the press notice is required" do
          click_link "Consultees, neighbours and publicity"
          click_link "Press notice"
          expect(find_by_id("press-notice-other-reason-selected-1-field")).to be_checked

          check("The application is for a Major Development")
          check("Wider Public interest")
          uncheck("Other")

          click_button("Save and mark as complete")
          click_link("Press notice")

          expect(find_by_id("press-notice-required-true-field")).to be_checked
          expect(find_by_id("press_notice_reason_major_development")).to be_checked
          expect(find_by_id("press_notice_reason_public_interest")).to be_checked
          expect(find_by_id("press-notice-other-reason-selected-1-field")).not_to be_checked

          expect(PressNotice.last).to have_attributes(
            planning_application_id: planning_application.id,
            required: true,
            reasons: { "environment" => "An environmental statement accompanies this application", "major_development" => "The application is for a Major Development", "public_interest" => "Wider Public interest" },
            requested_at: Time.zone.local(2023, 3, 15, 12)
          )

          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "press_notice",
            audit_comment: "Press notice has been marked as required with the following reasons: The application is for a Major Development, An environmental statement accompanies this application, Wider Public interest",
            user: assessor
          )
        end
      end

      context "when press notice has not been marked as required" do
        let!(:press_notice) { create(:press_notice, planning_application:) }

        it "I can mark the press notice as not required when it" do
          click_link "Consultees, neighbours and publicity"
          click_link "Press notice"

          choose("Yes")
          check("The application is for a Major Development")

          click_button("Save and mark as complete")
          click_link("Press notice")

          expect(find_by_id("press-notice-required-true-field")).to be_checked
          expect(find_by_id("press_notice_reason_major_development")).to be_checked

          expect(PressNotice.last).to have_attributes(
            planning_application_id: planning_application.id,
            required: true,
            reasons: {
              "major_development" => "The application is for a Major Development"
            },
            requested_at: Time.zone.local(2023, 3, 15, 12)
          )

          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "press_notice",
            audit_comment: "Press notice has been marked as required with the following reasons: The application is for a Major Development",
            user: assessor
          )
        end
      end
    end
  end
end
