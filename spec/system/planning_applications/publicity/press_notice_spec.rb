# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Press notice" do
  let!(:local_authority) { create(:local_authority, :default, press_notice_email: "pressnotice@example.com") }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let!(:planning_application) do
    create(:planning_application, :prior_approval, local_authority:)
  end

  before do
    sign_in assessor

    visit "/planning_applications/#{planning_application.id}"
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

      expect(page).to have_content("An email notification will be sent to pressnotice@example.com if a press notice is required.")
    end

    context "when a press notice is required" do
      it "I get an error when not providing a reason" do
        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"

        choose("Yes")
        click_button("Save and mark as complete")

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
          expect(page).to have_content("Provide a reason for the press notice")
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
        expect(find_by_id("press-notice-reasons-major-development-field")).to be_checked
        expect(find_by_id("press-notice-reasons-environment-field")).to be_checked

        perform_enqueued_jobs

        expect(PressNotice.last).to have_attributes(
          planning_application_id: planning_application.id,
          required: true,
          reasons: %w[major_development environment],
          requested_at: Time.zone.local(2023, 3, 15, 12)
        )

        audits = Audit.last(2)
        expect(audits.first).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice",
          audit_comment: "Press notice has been marked as required with the following reasons: major_development, environment",
          user: assessor
        )
        expect(audits.second).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice_mail",
          audit_comment: "Press notice request was sent to pressnotice@example.com",
          user: assessor
        )

        visit "/planning_applications/#{planning_application.id}/audits"
        within("#audit_#{audits.first.id}") do
          expect(page).to have_content("Press notice response added")
          expect(page).to have_content(assessor.name)
          expect(page).to have_content("Press notice has been marked as required with the following reasons: major_development, environment")
          expect(page).to have_content(audits.first.created_at.strftime("%d-%m-%Y %H:%M"))
        end
        within("#audit_#{audits.second.id}") do
          expect(page).to have_content("Request made for press notice")
          expect(page).to have_content(assessor.name)
          expect(page).to have_content("Press notice request was sent to pressnotice@example.com")
          expect(page).to have_content(audits.second.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end

      it "I provide a standard reason and another reason why a press notice is required" do
        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"

        choose("Yes")
        check("The application is for a Major Development")
        check("Other")
        fill_in(
          "Provide another reason why this application requires a press notice",
          with: "Another reason not included in the list"
        )

        click_button("Save and mark as complete")
        click_link("Press notice")

        expect(find_by_id("press-notice-required-true-field")).to be_checked
        expect(find_by_id("press-notice-reasons-major-development-field")).to be_checked
        expect(find_by_id("press-notice-reasons-other-field")).to be_checked

        perform_enqueued_jobs

        expect(PressNotice.last).to have_attributes(
          planning_application_id: planning_application.id,
          required: true,
          reasons: %w[major_development other],
          requested_at: Time.zone.local(2023, 3, 15, 12)
        )

        audits = Audit.last(2)
        expect(audits.first).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice",
          audit_comment: "Press notice has been marked as required with the following reasons: major_development, other",
          user: assessor
        )
        expect(audits.second).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice_mail",
          audit_comment: "Press notice request was sent to pressnotice@example.com",
          user: assessor
        )
      end

      it "I provide another reason why a press notice is required" do
        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"

        choose("Yes")
        check("Other")
        fill_in(
          "Provide another reason why this application requires a press notice",
          with: "Another reason not included in the list"
        )

        click_button("Save and mark as complete")
        click_link("Press notice")

        expect(find_by_id("press-notice-required-true-field")).to be_checked
        expect(find_by_id("press-notice-reasons-other-field")).to be_checked

        perform_enqueued_jobs

        expect(PressNotice.last).to have_attributes(
          planning_application_id: planning_application.id,
          required: true,
          reasons: %w[other],
          requested_at: Time.zone.local(2023, 3, 15, 12)
        )

        audits = Audit.last(2)
        expect(audits.first).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice",
          audit_comment: "Press notice has been marked as required with the following reasons: other",
          user: assessor
        )
        expect(audits.second).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice_mail",
          audit_comment: "Press notice request was sent to pressnotice@example.com",
          user: assessor
        )
      end

      it "sends an email to the press notice team" do
        delivered_emails = ActionMailer::Base.deliveries.count

        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"
        choose("Yes")
        check("The application is for a Major Development")
        click_button("Save and mark as complete")

        perform_enqueued_jobs

        expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
      end

      context "when no press notice email exists" do
        let!(:local_authority) { create(:local_authority, :default, press_notice_email: nil) }

        it "does not send an email to the press notice team" do
          delivered_emails = ActionMailer::Base.deliveries.count

          click_link "Consultees, neighbours and publicity"
          click_link "Press notice"
          choose("Yes")
          check("The application is for a Major Development")
          expect(page).to have_content("No press notice email has been set. This can be done by an administrator in the admin dashboard.")
          click_button("Save and mark as complete")

          perform_enqueued_jobs

          expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails)
        end
      end

      context "when press notice published at date has been set" do
        let!(:press_notice) { create(:press_notice, :required, planning_application:, published_at: Time.zone.now) }

        it "I cannot edit or submit the press notice response" do
          click_link "Consultees, neighbours and publicity"
          click_link "Press notice"

          expect(find_by_id("press-notice-required-true-field")).to be_disabled
          expect(find_by_id("press-notice-required-field")).to be_disabled
          expect(find_by_id("press-notice-reasons-other-field")).to be_disabled

          expect(page).not_to have_button("Save and mark as complete")
          expect(page).to have_content("Press notice published on #{press_notice.published_at.to_date.to_fs}")
        end
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
          reasons: [],
          requested_at: nil
        )

        expect(Audit.last).to have_attributes(
          planning_application_id: planning_application.id,
          activity_type: "press_notice",
          audit_comment: "Press notice has been marked as not required",
          user: assessor
        )
      end

      it "does not send an email to the press notice team" do
        delivered_emails = ActionMailer::Base.deliveries.count

        click_link "Consultees, neighbours and publicity"
        click_link "Press notice"
        choose("No")
        click_button("Save and mark as complete")

        expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails)
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
            reasons: [],
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
          expect(find_by_id("press-notice-reasons-other-field")).to be_checked

          check("The application is for a Major Development")
          check("Wider Public interest")
          uncheck("Other")

          click_button("Save and mark as complete")
          click_link("Press notice")

          expect(find_by_id("press-notice-required-true-field")).to be_checked
          expect(find_by_id("press-notice-reasons-major-development-field")).to be_checked
          expect(find_by_id("press-notice-reasons-public-interest-field")).to be_checked
          expect(find_by_id("press-notice-reasons-other-field")).not_to be_checked

          perform_enqueued_jobs

          expect(PressNotice.last).to have_attributes(
            planning_application_id: planning_application.id,
            required: true,
            reasons: %w[major_development environment public_interest],
            requested_at: Time.zone.local(2023, 3, 15, 12)
          )

          audits = Audit.last(2)
          expect(audits.first).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "press_notice",
            audit_comment: "Press notice has been marked as required with the following reasons: major_development, environment, public_interest",
            user: assessor
          )
          expect(audits.second).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "press_notice_mail",
            audit_comment: "Press notice request was sent to pressnotice@example.com",
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
          expect(find_by_id("press-notice-reasons-major-development-field")).to be_checked

          perform_enqueued_jobs

          expect(PressNotice.last).to have_attributes(
            planning_application_id: planning_application.id,
            required: true,
            reasons: %w[major_development],
            requested_at: Time.zone.local(2023, 3, 15, 12)
          )

          audits = Audit.last(2)
          expect(audits.first).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "press_notice",
            audit_comment: "Press notice has been marked as required with the following reasons: major_development",
            user: assessor
          )
          expect(audits.second).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "press_notice_mail",
            audit_comment: "Press notice request was sent to pressnotice@example.com",
            user: assessor
          )
        end
      end
    end
  end

  describe "confirming a press notice" do
    let(:consultation) { planning_application.consultation }

    before do
      travel_to "2023-09-20" do
        consultation.start_deadline
      end
    end

    context "when a press notice is required" do
      let!(:press_notice) { create(:press_notice, :required, planning_application:) }

      it "I can view the relevant information" do
        click_link "Consultees, neighbours and publicity"

        within("#confirm-press-notice") do
          expect(page).to have_content("Not started")
          click_link("Confirm press notice")
        end

        within("#planning-application-details") do
          expect(page).to have_content("Confirm press notice")
          expect(page).to have_content(planning_application.reference)
          expect(page).to have_content(planning_application.full_address)
          expect(page).to have_content(planning_application.description)
        end

        expect(page).to have_content("Press notice requested")
        expect(page).to have_content("Press notice requested on #{press_notice.requested_at.to_date.to_fs}")

        within(".govuk-breadcrumbs__list") do
          expect(page).to have_content("Confirm press notice")
        end

        expect(page).to have_content("Reasons selected:")
        expect(page).to have_content("An environmental statement accompanies this application")
        expect(page).to have_content("The application does not accord with the provisions of the development plan")
      end

      it "there is a validation error when saving unsupported file type" do
        click_link "Consultees, neighbours and publicity"
        click_link "Confirm press notice"

        attach_file("Upload photo(s)", "spec/fixtures/images/image.gif")
        click_button("Save")

        expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
      end

      it "I can confirm the press notice details" do
        click_link "Consultees, neighbours and publicity"
        click_link "Confirm press notice"

        click_button "Save"
        expect(page).to have_content("Provide the date when the press notice was sent")

        within("#press-sent-at-field") do
          expect(page).to have_content("What date was the press notice sent?")
          fill_in "Day", with: "1"
          fill_in "Month", with: "1"
          fill_in "Year", with: "2023"
        end

        click_button "Save"
        expect(page).to have_content("The date the press notice was sent must be on or after the consultation start date")

        within("#press-sent-at-field") do
          expect(page).to have_content("What date was the press notice sent?")
          fill_in "Day", with: "31"
          fill_in "Month", with: "12"
          fill_in "Year", with: "2023"
        end

        click_button "Save"
        expect(page).to have_content("The date the press notice was sent must be on or before today")

        within("#press-sent-at-field") do
          expect(page).to have_content("What date was the press notice sent?")
          fill_in "Day", with: "25"
          fill_in "Month", with: "9"
          fill_in "Year", with: "2023"
        end

        fill_in "Optional comment", with: "Press notice comment"
        click_button "Save"

        expect(page).to have_content("Press notice response has been successfully updated")

        within("#confirm-press-notice") do
          expect(page).to have_content("In progress")
          click_link("Confirm press notice")
        end

        within("#published-at-field") do
          expect(page).to have_content("What date was the press notice published?")
          fill_in "Day", with: "1"
          fill_in "Month", with: "1"
          fill_in "Year", with: "2023"
        end

        click_button "Save"
        expect(page).to have_content("The date the press notice was published must be on or after the press sent date")

        within("#published-at-field") do
          expect(page).to have_content("What date was the press notice published?")
          fill_in "Day", with: "31"
          fill_in "Month", with: "12"
          fill_in "Year", with: "2023"
        end

        click_button "Save"
        expect(page).to have_content("The date the press notice was published must be on or before today")

        within("#published-at-field") do
          expect(page).to have_content("What date was the press notice published?")
          fill_in "Day", with: "29"
          fill_in "Month", with: "9"
          fill_in "Year", with: "2023"
        end

        attach_file("Upload photo(s)", "spec/fixtures/images/proposed-floorplan.png")

        click_button "Save"

        within("#confirm-press-notice") do
          expect(page).to have_content("Complete")
          click_link("Confirm press notice")
        end

        within(".govuk-table") do
          document = PressNotice.last.documents.first
          expect(page).to have_content(document.name.to_s)
          expect(page).to have_link("View in new window")
          expect(page).to have_content("Press Notice")
          expect(page).to have_content(document.created_at.to_fs)
        end

        expect(PressNotice.last).to have_attributes(
          press_sent_at: Time.zone.local(2023, 9, 25),
          published_at: Time.zone.local(2023, 9, 29),
          comment: "Press notice comment"
        )
      end
    end

    context "when a press notice is not required" do
      let!(:press_notice) { create(:press_notice, required: false, planning_application:) }

      it "I cannot confirm the press notice" do
        click_link "Consultees, neighbours and publicity"
        expect(page).not_to have_content("Confirm press notice")

        visit "/planning_applications/#{planning_application.id}/press_notice/confirmation"
        expect(page).to have_current_path("/planning_applications/#{planning_application.id}/consultation")
        expect(page).to have_content("The press notice is not required so there is no need to confirm it")
      end
    end
  end
end
