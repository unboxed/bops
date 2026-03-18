# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Press notice" do
  let!(:local_authority) { create(:local_authority, :default, press_notice_email: "pressnotice@example.com") }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let!(:planning_application) do
    create(:planning_application, :published, :planning_permission, local_authority:, postcode: "")
  end

  let(:task) do
    planning_application.case_record.find_task_by_slug_path!(
      "consultees-neighbours-and-publicity/publicity/press-notice"
    )
  end

  let(:confirm_press_notice_task) do
    planning_application.case_record.find_task_by_slug_path!(
      "consultees-neighbours-and-publicity/publicity/confirm-press-notice"
    )
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  describe "responding to whether a press notice is required" do
    before { travel_to(Time.zone.local(2023, 3, 15, 12)) }

    it "shows the press notice item in the tasklist" do
      click_link "Consultees, neighbours and publicity"

      within :sidebar do
        expect(page).to have_link("Press notice")
      end
      expect(task.reload).to be_not_started
    end

    context "when a press notice is required" do
      it "I get an error when not providing a reason" do
        click_link "Consultees, neighbours and publicity"
        within :sidebar do
          click_link "Press notice"
        end
        choose("Yes")
        click_button("Save and mark as complete")

        within(".govuk-error-summary") do
          expect(page).to have_content("There is a problem")
          expect(page).to have_content("Select a reason for the press notice")
        end
      end

      it "I provide reasons why a press notice is required" do
        click_link "Consultees, neighbours and publicity"
        within :sidebar do
          click_link "Press notice"
        end

        choose("Yes")
        check("The application is for a Major Development")
        check("An environmental statement accompanies this application")

        click_button("Save and mark as complete")
        expect(page).to have_content("Successfully saved press notice requirement")
        expect(page).to have_content("Press notice has been marked as required and email notification has been sent to #{local_authority.press_notice_email}")
        expect(task.reload).to be_completed

        expect(find_by_id("tasks-press-notice-form-required-true-field")).to be_checked
        expect(find_by_id("tasks-press-notice-form-reasons-major-development-field")).to be_checked
        expect(find_by_id("tasks-press-notice-form-reasons-environment-field")).to be_checked

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

        visit "/planning_applications/#{planning_application.reference}/audits"
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
        within :sidebar do
          click_link "Press notice"
        end

        choose("Yes")
        check("The application is for a Major Development")
        check("Other")
        fill_in(
          "Provide another reason why this application requires a press notice",
          with: "Another reason not included in the list"
        )

        click_button("Save and mark as complete")

        expect(find_by_id("tasks-press-notice-form-required-true-field")).to be_checked
        expect(find_by_id("tasks-press-notice-form-reasons-major-development-field")).to be_checked
        expect(find_by_id("tasks-press-notice-form-reasons-other-field")).to be_checked

        expect(page).to have_content("Press notice has been marked as required and email notification has been sent to #{local_authority.press_notice_email}.")
        expect(task.reload).to be_completed

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

      it "sends an email to the press notice team" do
        delivered_emails = ActionMailer::Base.deliveries.count

        click_link "Consultees, neighbours and publicity"
        within :sidebar do
          click_link "Press notice"
        end
        choose("Yes")
        check("The application is for a Major Development")
        click_button("Save and mark as complete")

        perform_enqueued_jobs

        expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to contain_exactly(local_authority.press_notice_email)
        expect(email.body.encoded).to include(planning_application.reference_in_full)
        expect(email.body.encoded).to include("/planning_applications/#{planning_application.reference}/consultees-neighbours-and-publicity/publicity/confirm-press-notice")
        expect(email.body.encoded).to include("Major Development")

        expect(task.reload).to be_completed
      end

      it "allows publication details to be confirmed", capybara: true do
        click_link "Consultees, neighbours and publicity"
        within :sidebar do
          click_link "Press notice"
        end

        choose("Yes")
        check("The application is for a Major Development")

        click_button("Save and mark as complete")
        expect(page).to have_content("Successfully saved press notice requirement")
        expect(task.reload).to be_completed
        perform_enqueued_jobs
        press_notice = planning_application.press_notices.last

        within :sidebar do
          click_link "Confirm press notice"
        end

        expect(page).to have_content("Confirm press notice")

        expect(page).to have_content("Not yet published")
        expect(page).to have_content(press_notice.requested_at.to_date.to_fs)
        click_link("Confirm publication")

        expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/consultees-neighbours-and-publicity/publicity/confirm-press-notice/#{press_notice.id}/edit")
        expect(page).to have_content("Reasons selected:")
        expect(page).to have_content("The application is for a Major Development")
        fill_in "Day", with: 16
        fill_in "Month", with: 3
        fill_in "Year", with: 2023

        click_button "Confirm publication"

        expect(page).to have_content "Successfully confirmed press notice publication"
        expect(page).to have_content("Published")
        expect(page).not_to have_link("Confirm publication")
        expect(page).to have_link("Edit publication details")
        expect(confirm_press_notice_task.reload).to be_in_progress

        click_button "Save and mark as complete"

        expect(page).to have_content("Successfully confirmed press notice publication")
        expect(page).to have_content("16 Mar 2023")
        expect(confirm_press_notice_task.reload).to be_completed
      end

      context "when no press notice email exists" do
        let!(:local_authority) { create(:local_authority, :default, press_notice_email: nil) }

        it "does not send an email to the press notice team" do
          delivered_emails = ActionMailer::Base.deliveries.count

          click_link "Consultees, neighbours and publicity"
          within :sidebar do
            click_link "Press notice"
          end
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
          within :sidebar do
            click_link "Press notice"
          end

          expect(find_by_id("tasks-press-notice-form-required-true-field")).to be_disabled
          expect(find_by_id("tasks-press-notice-form-required-field")).to be_disabled
          expect(find_by_id("tasks-press-notice-form-reasons-other-field")).to be_disabled

          expect(page).to have_content("Press notice published on #{press_notice.published_at.to_date.to_fs}")
        end

        it "I can add another press notice" do
          click_link "Consultees, neighbours and publicity"

          within :sidebar do
            click_link "Press notice"
          end

          expect(planning_application.press_notices.length).to eq(1)

          expect(page).to have_link "Add a new press notice response"
          click_link "Add a new press notice response"
          expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/consultees-neighbours-and-publicity/publicity/press-notice?new=true")

          expect(find_by_id("tasks-press-notice-form-required-true-field")).not_to be_disabled
          choose("Yes")
          check("The application is for a Major Development")
          click_button("Save and mark as complete")

          expect(page).to have_content("Successfully saved press notice requirement")

          expect(planning_application.press_notices.reload.length).to eq(2)
        end
      end
    end

    context "when a press notice is not required" do
      it "I can mark it as not required" do
        click_link "Consultees, neighbours and publicity"
        within :sidebar do
          click_link "Press notice"
        end
        choose("No")

        click_button("Save and mark as complete")

        expect(page).to have_content("Successfully saved press notice requirement")
        expect(task.reload).to be_completed

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
        within :sidebar do
          click_link "Press notice"
        end
        choose("No")
        click_button("Save and mark as complete")

        perform_enqueued_jobs

        expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails)
      end
    end

    context "when editing a press notice" do
      context "when press notice has been marked as required" do
        let!(:press_notice) { create(:press_notice, :with_other_reason, planning_application:, requested_at: Time.zone.local(2023, 3, 14, 12)) }

        it "I can mark a press notice as not required after it was marked as required" do
          click_link "Consultees, neighbours and publicity"
          within :sidebar do
            click_link "Press notice"
          end
          choose("No")

          click_button("Save and mark as complete")
          within :sidebar do
            click_link "Press notice"
          end
          expect(find_by_id("tasks-press-notice-form-required-field")).to be_checked

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
          within :sidebar do
            click_link "Press notice"
          end
          expect(find_by_id("tasks-press-notice-form-reasons-other-field")).to be_checked

          check("The application is for a Major Development")
          check("Wider Public interest")
          uncheck("Other")

          click_button("Save and mark as complete")

          expect(find_by_id("tasks-press-notice-form-required-true-field")).to be_checked
          expect(find_by_id("tasks-press-notice-form-reasons-major-development-field")).to be_checked
          expect(find_by_id("tasks-press-notice-form-reasons-public-interest-field")).to be_checked
          expect(find_by_id("tasks-press-notice-form-reasons-other-field")).not_to be_checked

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

        it "I can mark the press notice as required when it was not previously required" do
          click_link "Consultees, neighbours and publicity"
          within :sidebar do
            click_link "Press notice"
          end
          choose("Yes")
          check("The application is for a Major Development")

          click_button("Save and mark as complete")

          expect(find_by_id("tasks-press-notice-form-required-true-field")).to be_checked
          expect(find_by_id("tasks-press-notice-form-reasons-major-development-field")).to be_checked

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
end
