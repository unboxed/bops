# frozen_string_literal: true

require "rails_helper"

RSpec.describe "checking publicity" do
  let!(:local_authority) { create(:local_authority, :default, press_notice_email: "pressnotices@example.com") }

  let!(:assessor) do
    create(:user, :assessor, name: "Alice Smith", local_authority: local_authority)
  end

  let!(:uploader) do
    create(:user, :assessor, name: "Bob Jones", local_authority: local_authority)
  end

  let!(:reviewer) do
    create(:user, :reviewer, local_authority: local_authority)
  end

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :planning_permission, local_authority: local_authority)
  end

  let!(:consultation) do
    planning_application.consultation
  end

  before do
    create(:decision, :householder_granted)
    create(:decision, :householder_refused)

    create(:recommendation, planning_application:)

    sign_in reviewer
  end

  context "when the publicity has been confirmed correctly" do
    let!(:site_notice) do
      create(:site_notice,
        planning_application: planning_application,
        required: true,
        displayed_at: "2024-01-08T09:00:00Z",
        expiry_date: "2024-01-30",
        internal_team_email: "pressteam@example.com")
    end

    let!(:press_notice) do
      create(:press_notice,
        planning_application: planning_application,
        required: true,
        reasons: ["major_development"],
        requested_at: "2024-01-08T09:00:00Z",
        published_at: "2024-01-11T09:00:00Z",
        expiry_date: "2024-02-01")
    end

    let!(:site_notice_evidence) do
      create(:document,
        planning_application: planning_application,
        owner: site_notice,
        user: uploader,
        file: fixture_file_upload("site-notice.jpg", "image/jpeg", true),
        tags: ["internal.siteNotice"])
    end

    let!(:press_notice_evidence) do
      create(:document,
        planning_application: planning_application,
        owner: press_notice,
        user: uploader,
        file: fixture_file_upload("press-notice.jpg", "image/jpeg", true),
        tags: ["internal.pressNotice"])
    end

    context "when the assessor hasn't assessed the publicity" do
      it "allows a reviewer to mark the publicity check as complete" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-publicities") do
          expect(page).to have_content("Check publicity")
          expect(page).to have_content("Not started")
        end

        click_button "Check publicity"

        within("#site-notice-check") do
          expect(page).to have_selector("h2", text: "Check site notice")

          within "tbody tr:nth-child(1)" do
            expect(page).to have_selector("td:nth-child(1)", text: "08/01/2024")
            expect(page).to have_selector("td:nth-child(2)", text: "Bob Jones")
            expect(page).to have_selector("td:nth-child(3)", text: "30/01/2024")
          end

          expect(page).to have_selector("a", text: "View in new window")
          expect(page).to have_selector("a", text: "View more documents")

          expect(page).to have_content("File name: site-notice.jpg")
        end

        within("#press-notice-check") do
          expect(page).to have_selector("h2", text: "Check press notice")

          within "tbody tr:nth-child(1)" do
            expect(page).to have_selector("td:nth-child(1)", text: "Major development")
            expect(page).to have_selector("td:nth-child(2)", text: "11/01/2024")
            expect(page).to have_selector("td:nth-child(3)", text: "Bob Jones")
            expect(page).to have_selector("td:nth-child(4)", text: "01/02/2024")
          end

          expect(page).to have_selector("a", text: "View in new window")
          expect(page).to have_selector("a", text: "View more documents")

          expect(page).to have_content("File name: press-notice.jpg")
        end

        within("#review-publicities") do
          choose "Agree"
          click_button "Save and mark as complete"
        end

        expect(page).to have_selector("[role=alert] p", text: "Review of publicity successfully added.")

        within("#review-publicities") do
          expect(page).to have_content("Check publicity")
          expect(page).to have_content("Completed")
        end
      end

      it "allows a reviewer to return the application to the assessor" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-publicities") do
          expect(page).to have_content("Check publicity")
          expect(page).to have_content("Not started")
        end

        click_button "Check publicity"

        within("#review-publicities") do
          choose "Return with comments"
          fill_in "Add a comment", with: "Check this"
          click_button "Save and mark as complete"
        end

        expect(page).to have_selector("[role=alert] p", text: "Review of publicity successfully added.")

        within("#review-publicities") do
          expect(page).to have_content("Check publicity")
          expect(page).to have_content("Awaiting changes")
        end

        click_link "Sign off recommendation"

        expect(page).to have_content "You have suggested changes to be made by the officer."

        choose "No (return the case for assessment)"
        fill_in "Explain to the officer why the case is being returned", with: "More publicity"
        click_button "Save and mark as complete"

        click_link "Application"

        expect(page).to have_list_item_for(
          "Check and assess",
          with: "To be reviewed"
        )

        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Check site notice and press notice",
          with: "To be reviewed"
        )

        click_link "Check site notice and press notice"

        expect(page).to have_content "Check this"

        click_button "Save and mark as complete"

        expect(page).to have_list_item_for(
          "Check site notice and press notice",
          with: "Completed"
        )

        click_link "Make draft recommendation"

        click_button "Update"

        click_link "Review and submit recommendation"

        click_button "Submit recommendation"

        click_link "Review and sign-off"

        within("#review-publicities") do
          expect(page).to have_content("Check publicity")
          expect(page).to have_content("Not started")
        end
      end

      it "shows errors" do
        visit "/planning_applications/#{planning_application.reference}/review/tasks"

        within("#review-publicities") do
          expect(page).to have_content("Check publicity")
          expect(page).to have_content("Not started")
        end

        click_button "Check publicity"

        within("#review-publicities") do
          click_button "Save and mark as complete"
        end

        expect(page).to have_content "Determine whether this is correct"
        expect(page).not_to have_content "You must add a comment"

        within("#review-publicities") do
          choose "Return with comments"
          click_button "Save and mark as complete"
        end

        expect(page).to have_content "You must add a comment"
      end
    end
  end

  context "when the publicity has been checked" do
    let!(:site_notice) do
      create(:site_notice,
        planning_application: planning_application,
        required: true,
        displayed_at: "2024-01-08T09:00:00Z",
        expiry_date: "2024-01-30",
        internal_team_email: "pressteam@example.com")
    end

    let!(:press_notice) do
      create(:press_notice,
        planning_application: planning_application,
        required: true,
        reasons: ["major_development"],
        requested_at: "2024-01-08T09:00:00Z",
        published_at: "2024-01-11T09:00:00Z",
        expiry_date: "2024-02-01")
    end

    let!(:site_notice_evidence) do
      create(:document,
        planning_application: planning_application,
        owner: site_notice,
        user: uploader,
        file: fixture_file_upload("site-notice.jpg", "image/jpeg", true),
        tags: ["internal.siteNotice"])
    end

    let!(:press_notice_evidence) do
      create(:document,
        planning_application: planning_application,
        owner: press_notice,
        user: uploader,
        file: fixture_file_upload("press-notice.jpg", "image/jpeg", true),
        tags: ["internal.pressNotice"])
    end

    let!(:assessment_detail) do
      create(:assessment_detail,
        planning_application: planning_application,
        user: assessor,
        assessment_status: "complete",
        category: "check_publicity")
    end

    it "the reviewer can accept" do
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      within("#review-publicities") do
        expect(page).to have_content("Check publicity")
        expect(page).to have_content("Not started")
      end

      click_button "Check publicity"

      within("#site-notice-check") do
        expect(page).to have_selector("h2", text: "Check site notice")

        within "tbody tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "08/01/2024")
          expect(page).to have_selector("td:nth-child(2)", text: "Bob Jones")
          expect(page).to have_selector("td:nth-child(3)", text: "30/01/2024")
        end

        expect(page).to have_selector("a", text: "View in new window")
        expect(page).to have_selector("a", text: "View more documents")

        expect(page).to have_content("File name: site-notice.jpg")
      end

      within("#press-notice-check") do
        expect(page).to have_selector("h2", text: "Check press notice")

        within "tbody tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Major development")
          expect(page).to have_selector("td:nth-child(2)", text: "11/01/2024")
          expect(page).to have_selector("td:nth-child(3)", text: "Bob Jones")
          expect(page).to have_selector("td:nth-child(4)", text: "01/02/2024")
        end

        expect(page).to have_selector("a", text: "View in new window")
        expect(page).to have_selector("a", text: "View more documents")

        expect(page).to have_content("File name: press-notice.jpg")
      end

      within("#review-publicities") do
        choose "Agree"
        click_button "Save and mark as complete"
      end
      expect(page).to have_selector("[role=alert] p", text: "Review of publicity successfully added.")

      within("#review-publicities") do
        expect(page).to have_content("Check publicity")
        expect(page).to have_content("Completed")
      end
    end

    it "allows a reviewer to return the application to the assessor" do
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      within("#review-publicities") do
        expect(page).to have_content("Check publicity")
        expect(page).to have_content("Not started")
      end

      click_button "Check publicity"

      within("#review-publicities") do
        choose "Return with comments"
        fill_in "Add a comment", with: "Check this"
        click_button "Save and mark as complete"
      end

      expect(page).to have_selector("[role=alert] p", text: "Review of publicity successfully added.")

      within("#review-publicities") do
        expect(page).to have_content("Check publicity")
        expect(page).to have_content("Awaiting changes")
      end

      click_link "Sign off recommendation"

      expect(page).to have_content "You have suggested changes to be made by the officer."

      choose "No (return the case for assessment)"
      fill_in "Explain to the officer why the case is being returned", with: "More publicity"

      click_button "Save and mark as complete"

      click_link "Application"

      expect(page).to have_list_item_for(
        "Check and assess",
        with: "To be reviewed"
      )

      click_link "Check and assess"

      expect(page).to have_list_item_for(
        "Check site notice and press notice",
        with: "To be reviewed"
      )

      click_link "Check site notice and press notice"

      expect(page).to have_content "Check this"

      click_button "Save and mark as complete"

      expect(page).to have_list_item_for(
        "Check site notice and press notice",
        with: "Completed"
      )

      click_link "Make draft recommendation"

      click_button "Update"

      click_link "Review and submit recommendation"

      click_button "Submit recommendation"

      click_link "Review and sign-off"

      within("#review-publicities") do
        expect(page).to have_content("Check publicity")
        expect(page).to have_content("Not started")
      end
    end

    it "shows errors" do
      visit "/planning_applications/#{planning_application.reference}/review/tasks"

      within("#review-publicities") do
        expect(page).to have_content("Check publicity")
        expect(page).to have_content("Not started")
      end

      click_button "Check publicity"

      within("#review-publicities") do
        click_button "Save and mark as complete"
      end

      expect(page).to have_content "Determine whether this is correct"
      expect(page).not_to have_content "You must add a comment"

      within("#review-publicities") do
        choose "Return with comments"
        click_button "Save and mark as complete"
      end

      expect(page).to have_content "You must add a comment"
    end
  end
end
