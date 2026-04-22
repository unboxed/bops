# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check description task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-assess/assessment-summaries/check-publicity") }

  %i[planning_permission prior_approval].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, local_authority:)
      end

      before do
        sign_in(user)
        visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
      end

      it "allows the task to be marked as complete" do
        within :sidebar do
          click_link "Check publicity"
        end

        click_button "Save and mark as complete"

        expect(task).to be_completed
      end
    end
  end

  describe "site notice section", :capybara do
    let(:planning_application) { create(:planning_application, :planning_permission, local_authority:) }

    before { sign_in(user) }

    context "when no site notice exists" do
      before do
        visit "/planning_applications/#{planning_application.reference}/check-and-assess/assessment-summaries/check-publicity"
      end

      it "shows create site notice link in banner and section" do
        within ".govuk-notification-banner" do
          expect(page).to have_content("Site notice task incomplete")
          expect(page).to have_link("Create site notice")
        end

        within "#site-notice-check" do
          expect(page).to have_content("Site notice task incomplete")
          expect(page).to have_link("Create site notice")
        end
      end
    end

    context "when site notice is marked as not required" do
      before do
        create(:site_notice, planning_application:, required: false)
        visit "/planning_applications/#{planning_application.reference}/check-and-assess/assessment-summaries/check-publicity"
      end

      it "shows not required message and link to mark as required" do
        within "#site-notice-check" do
          expect(page).to have_content("Site notice not required")
          expect(page).to have_link("Mark site notice as required")
        end
      end
    end

    context "when site notice exists but has not been displayed" do
      before do
        create(:site_notice, planning_application:)
        visit "/planning_applications/#{planning_application.reference}/check-and-assess/assessment-summaries/check-publicity"
      end

      it "shows confirm link in banner and incomplete evidence section" do
        within ".govuk-notification-banner" do
          expect(page).to have_content("Site notice task incomplete")
          expect(page).to have_link("Confirm site notice")
        end

        within "#site-notice-check" do
          expect(page).to have_content("–")
          expect(page).to have_content("Evidence of site notice")
          expect(page).to have_content("No documents uploaded")
          expect(page).to have_link("Confirm display")
        end
      end
    end

    context "when site notice has been displayed" do
      before do
        create(:site_notice, planning_application:, displayed_at: Date.new(2026, 1, 1))
        visit "/planning_applications/#{planning_application.reference}/check-and-assess/assessment-summaries/check-publicity"
      end

      it "shows display date in table and no documents message" do
        within ".govuk-notification-banner" do
          expect(page).not_to have_link("Create site notice")
          expect(page).not_to have_link("Confirm site notice")
        end

        within "#site-notice-check" do
          expect(page).to have_content("01/01/2026")
          expect(page).to have_content("No documents uploaded")
          expect(page).to have_link("Confirm display")
        end
      end
    end
  end

  describe "press notice section", :capybara do
    let(:planning_application) { create(:planning_application, :planning_permission, local_authority:) }

    before { sign_in(user) }

    context "when no press notice exists" do
      before do
        visit "/planning_applications/#{planning_application.reference}/check-and-assess/assessment-summaries/check-publicity"
      end

      it "shows create press notice link in banner and section" do
        within ".govuk-notification-banner" do
          expect(page).to have_content("Press notice task incomplete")
          expect(page).to have_link("Create press notice")
        end

        within "#press-notice-check" do
          expect(page).to have_content("Press notice task incomplete")
          expect(page).to have_link("Create press notice")
        end
      end
    end

    context "when press notice is marked as not required" do
      before do
        create(:press_notice, planning_application:)
        visit "/planning_applications/#{planning_application.reference}/check-and-assess/assessment-summaries/check-publicity"
      end

      it "shows not required message and link to mark as required" do
        within ".govuk-notification-banner" do
          expect(page).not_to have_link("Create press notice")
          expect(page).not_to have_link("Confirm press notice")
        end

        within "#press-notice-check" do
          expect(page).to have_content("Press notice marked as not required for this application")
          expect(page).to have_link("Mark press notice as required")
        end
      end
    end

    context "when press notice exists but has not been published" do
      before do
        create(:press_notice, :required, planning_application:)
        visit "/planning_applications/#{planning_application.reference}/check-and-assess/assessment-summaries/check-publicity"
      end

      it "shows confirm link in banner and incomplete evidence section" do
        within ".govuk-notification-banner" do
          expect(page).to have_content("Press notice task incomplete")
          expect(page).to have_link("Confirm press notice")
        end

        within "#press-notice-check" do
          expect(page).to have_content("–")
          expect(page).to have_content("Evidence of press notice")
          expect(page).to have_content("No documents uploaded")
          expect(page).to have_link("Upload evidence")
        end
      end
    end

    context "when press notice has been published" do
      before do
        create(:press_notice, :required, planning_application:, published_at: Date.new(2026, 1, 1))
        visit "/planning_applications/#{planning_application.reference}/check-and-assess/assessment-summaries/check-publicity"
      end

      it "shows publication date in table and no documents message" do
        within ".govuk-notification-banner" do
          expect(page).not_to have_link("Create press notice")
          expect(page).not_to have_link("Confirm press notice")
        end

        within "#press-notice-check" do
          expect(page).to have_content("01/01/2026")
          expect(page).to have_content("No documents uploaded")
          expect(page).to have_link("Upload evidence")
        end
      end
    end
  end
end
