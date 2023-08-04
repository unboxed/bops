# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment" do
  let!(:default_local_authority) do
    create(
      :local_authority,
      :default,
      reviewer_group_email: "reviewers@example.com"
    )
  end

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority: default_local_authority,
      name: "Alice Aplin"
    )
  end

  let(:reviewer) do
    create(
      :user,
      :reviewer,
      local_authority: default_local_authority,
      name: "Bella Brook"
    )
  end

  context "when application type is lawfulness_certificate" do
    let!(:planning_application) do
      travel_to("2022-01-01") do
        create(
          :planning_application,
          :with_constraints,
          local_authority: default_local_authority,
          public_comment: nil
        )
      end
    end

    before do
      sign_in assessor
      visit planning_applications_path
    end

    it "shows the correct status tags at each stage" do
      visit planning_application_assessment_tasks_path(planning_application)

      expect(list_item("Make draft recommendation")).to have_content("Not started")

      click_link("Make draft recommendation")
      choose("Yes")

      fill_in(
        "State the reasons why this application is, or is not lawful.",
        with: "Application valid."
      )

      fill_in(
        "Provide supporting information for your manager.",
        with: "Requirements met."
      )

      click_button("Save and come back later")

      expect(list_item("Make draft recommendation")).to have_content("In progress")

      click_link("Make draft recommendation")
      click_button("Save and mark as complete")

      expect(list_item("Make draft recommendation")).to have_content("Completed")

      visit(planning_application_path(planning_application))
      ["Not started", "In progress", "Completed"].each do |status|
        expect(list_item("View recommendation")).not_to have_content(status)
      end

      click_link("Check and assess")
      click_link("Review and submit recommendation")
      click_button("Submit recommendation")

      visit(planning_application_path(planning_application))

      expect(list_item("View recommendation")).to have_content("Awaiting determination")

      sign_in(reviewer)
      visit(planning_application_path(planning_application))

      expect(list_item("Review and sign-off")).to have_content("Not started")

      click_link("Review and sign-off")

      expect(list_item("Sign-off recommendation")).to have_content("Not started")

      click_link("Sign-off recommendation")
      choose("No (return the case for assessment)")

      fill_in(
        "Explain to the officer why the case is being returned",
        with: "Application invalid"
      )

      click_button("Save and come back later")

      expect(list_item("Sign-off recommendation")).to have_content("In progress")
      click_link("Back")
      expect(list_item("Review and sign-off")).to have_content("In progress")

      click_link("Review and sign-off")
      click_link("Sign-off recommendation")
      click_button("Save and mark as complete")

      expect(list_item("Sign-off recommendation")).to have_content("Completed")
      click_link("Back")
      expect(list_item("Review and sign-off")).to have_content("Completed")

      click_link("Check and assess")
      within "#complete-assessment-tasks" do
        ["Not started", "In progress", "Completed"].each do |status|
          expect(list_item("Make draft recommendation")).not_to have_content(status)
        end
      end

      sign_in(assessor)
      visit(planning_application_path(planning_application))

      click_link("Check and assess")
      click_link("Make draft recommendation")

      fill_in(
        "State the reasons why this application is, or is not lawful.",
        with: "Amended reason."
      )

      click_button("Update")

      expect(list_item("Make draft recommendation")).to have_content("Completed")

      click_link("Review and submit recommendation")
      click_button("Submit recommendation")

      expect(list_item("View recommendation")).to have_content("Awaiting determination")

      sign_in(reviewer)
      visit(planning_application_path(planning_application))

      expect(list_item("Review and sign-off")).to have_content("Not started")

      click_link("Review and sign-off")
      click_link("Sign-off recommendation")
      choose("Yes (decision is ready to be published)")
      click_button("Save and mark as complete")

      expect(list_item("Sign-off recommendation")).to have_content("Completed")
      click_link("Back")
      expect(list_item("Review and sign-off")).to have_content("Completed")

      click_link("Check and assess")
      expect(list_item("Make draft recommendation")).to have_content("Completed")

      sign_in(assessor)
      visit(planning_application_path(planning_application))

      expect(list_item("View recommendation")).to have_content("Completed")
    end

    context "when clicking Save and mark as complete" do
      context "with no previous recommendations" do
        it "can create a new recommendation, edit it, and submit it" do
          within(selected_govuk_tab) do
            click_link(planning_application.reference)
          end

          click_link("Check and assess")
          click_link("Make draft recommendation")
          choose "Yes"
          fill_in "State the reasons why this application is, or is not lawful.", with: "This is a public comment"
          fill_in "Provide supporting information for your manager.", with: "This is a private assessor comment"
          click_button "Save and mark as complete"

          planning_application.reload
          expect(planning_application.recommendations.count).to eq(1)
          expect(planning_application.public_comment).to eq("This is a public comment")
          expect(planning_application.recommendations.first.assessor_comment).to eq("This is a private assessor comment")
          expect(planning_application.decision).to eq("granted")

          click_link("Make draft recommendation")
          expect(page).to have_checked_field("Yes")
          expect(page).to have_field("Provide supporting information for your manager.",
                                     with: "This is a private assessor comment")
          choose "No"
          fill_in "State the reasons why this application is, or is not lawful.", with: "This is a new public comment"
          fill_in "Provide supporting information for your manager.", with: "Edited private assessor comment"
          click_button "Update assessment"
          planning_application.reload

          expect(planning_application.recommendations.count).to eq(1)
          expect(planning_application.recommendations.first.assessor_comment).to eq("Edited private assessor comment")
          expect(planning_application.decision).to eq("refused")
          expect(planning_application.public_comment).to eq("This is a new public comment")

          click_link "Review and submit recommendation"

          expect(page).to have_content("We certify that on the date of the application")
          expect(page).to have_content("not lawful")
          expect(page).to have_content("aggrieved")

          expect(page).to have_content("If you agree with this decision notice, submit it to your line manager.")

          click_button "Submit recommendation"

          expect(page).to have_content("Recommendation was successfully submitted.")

          within "#assess-section" do
            click_link "Check and assess"
          end

          within "#complete-assessment-tasks" do
            expect(list_item("Make draft recommendation")).to have_content("Completed")
          end

          perform_enqueued_jobs
          update_notification = ActionMailer::Base.deliveries.last

          expect(update_notification.to).to contain_exactly(
            "reviewers@example.com"
          )

          expect(update_notification.subject).to eq(
            "BoPS case PlanX-22-00100-LDCP has a new update"
          )

          planning_application.reload
          expect(planning_application.status).to eq("awaiting_determination")

          visit planning_application_path(planning_application)
          click_link "View recommendation"
          expect(page).to have_text("Recommendations submitted by #{planning_application.recommendations.first.assessor.name}")

          click_link "Back"

          click_button "Audit log"
          click_link "View all audits"

          expect(page).to have_text("Recommendation submitted")
          expect(page).to have_text(assessor.name)
          expect(page).to have_text("Assessor comment: Edited private assessor comment")
          expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end

      it "shows errors if decision and public comment are blank" do
        visit(new_planning_application_recommendation_path(planning_application))
        click_button("Save and mark as complete")

        expect(page).to have_content("Please select Yes or No")

        expect(page).to have_content(
          "Please state the reasons why this application is, or is not lawful"
        )
      end
    end

    context "with previous recommendations" do
      let!(:planning_application) do
        create(:planning_application, :to_be_reviewed, local_authority: default_local_authority)
      end

      let!(:recommendation) do
        create(:recommendation, :reviewed, planning_application:,
                                           reviewer_comment: "I disagree", assessor_comment: "This looks good")
      end

      it "displays the previous recommendations" do
        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link("Check and assess")
        click_link("Make draft recommendation")

        within ".recommendations" do
          expect(page).to have_content("I disagree")
          expect(page).to have_content("This looks good")
        end

        choose "Yes"
        fill_in "State the reasons why this application is, or is not lawful.",
                with: "This is so granted and GDPO everything"
        fill_in "Provide supporting information for your manager.", with: "This is a private assessor comment"
        click_button "Update assessment"

        planning_application.reload
        expect(planning_application.recommendations.count).to eq(2)
        expect(planning_application.public_comment).to eq("This is so granted and GDPO everything")
        expect(planning_application.recommendation.assessor_comment).to eq("This is a private assessor comment")
        expect(planning_application.decision).to eq("granted")

        click_link("Make draft recommendation")

        within ".recommendations" do
          expect(page).to have_content("I disagree")
          expect(page).to have_content("This looks good")
          expect(page).not_to have_content("This is a private assessor comment")
        end

        expect(page).to have_checked_field("Yes")
        expect(page).to have_field("Provide supporting information for your manager.",
                                   with: "This is a private assessor comment")
      end
    end

    context "when submitting a recommendation" do
      it "can only be submitted when a planning application is in assessment" do
        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link("Check and assess")
        click_link("Make draft recommendation")

        expect(page).to have_content(
          "There is no legislation assessment for this application."
        )

        choose("Yes")
        fill_in("State the reasons why this application is, or is not lawful.", with: "This is a public comment")
        fill_in("Provide supporting information for your manager.", with: "This is a private assessor comment")
        click_button("Save and mark as complete")

        click_link("Review and submit recommendation")
        click_button("Submit recommendation")

        expect(page).to have_content("Recommendation was successfully submitted.")
        expect(page).to have_current_path(planning_application_path(planning_application))
        click_link("View recommendation")
        within(".govuk-button-group") do
          expect(page).to have_button("Withdraw recommendation")
          expect(page).not_to have_button("Submit recommendation")
        end
        expect(planning_application.reload.status).to eq("awaiting_determination")

        visit submit_recommendation_planning_application_path(planning_application)
        expect(page).to have_content("Not Found")
        visit planning_application_path(planning_application)

        # Check latest audit
        click_button "Audit log"

        expect(page).to have_content("Recommendation submitted")
        expect(page).to have_text("Alice Aplin")

        expect(page).to have_text(
          "Assessor comment: This is a private assessor comment"
        )

        click_link("View all audits")

        # Check audit logs
        within("#audit_#{Audit.last.id}") do
          expect(page).to have_content("Recommendation submitted")
          expect(page).to have_text("Assessor comment: This is a private assessor comment")
          expect(page).to have_text(assessor.name)
          expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end

      it "allows navigation to assess recommendation page" do
        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link("Check and assess")
        click_link("Make draft recommendation")

        choose("Yes")
        fill_in("State the reasons why this application is, or is not lawful.", with: "This is a public comment")
        click_button("Save and mark as complete")

        click_link("Review and submit recommendation")

        click_link("Edit recommendation")

        expect(page).to have_title("Make draft recommendation")
      end

      it "allows navigation back to the planning application page" do
        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link("Check and assess")
        click_link("Make draft recommendation")

        choose("Yes")
        fill_in("State the reasons why this application is, or is not lawful.", with: "This is a public comment")
        click_button("Save and mark as complete")

        click_link("Review and submit recommendation")

        click_link("Back")

        expect(page).to have_title("Planning Application")
      end

      context "when there are open post validation requests" do
        let!(:planning_application) { create(:in_assessment_planning_application, local_authority: default_local_authority) }
        let!(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :open, :post_validation, planning_application:) }

        it "prevents me from submitting the planning application" do
          within(selected_govuk_tab) do
            click_link(planning_application.reference)
          end

          click_link("Check and assess")
          click_link("Make draft recommendation")
          choose("Yes")
          fill_in("State the reasons why this application is, or is not lawful.", with: "This is a public comment")
          fill_in("Provide supporting information for your manager.", with: "This is a private assessor comment")
          click_button("Save and mark as complete")

          click_link("Review and submit recommendation")
          click_button("Submit recommendation")

          within(".govuk-error-summary") do
            expect(page).to have_content("There is a problem")
            expect(page).to have_content("This application has open non-validation requests. Please review open requests and resolve them before submitting to your manager.")
            expect(page).to have_link("review open requests", href: post_validation_requests_planning_application_validation_requests_path(planning_application))
          end

          expect(planning_application).to be_in_assessment
        end
      end
    end

    context "when withdrawing a recommendation" do
      let!(:planning_application) do
        create(:planning_application, :with_recommendation, :awaiting_determination, local_authority: default_local_authority, decision: "granted")
      end

      it "can only be withdrawn when a planning application is awaiting determination" do
        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link("View recommendation")

        within(".govuk-button-group") do
          expect(page).to have_link("Back", href: planning_application_path(planning_application))

          accept_confirm(text: "Are you sure you want to withdraw this recommendation?") do
            click_button("Withdraw recommendation")
          end
        end

        expect(page).to have_content("Recommendation was successfully withdrawn.")
        expect(page).to have_current_path(submit_recommendation_planning_application_path(planning_application))
        expect(page).to have_button("Submit recommendation")
        expect(page).not_to have_button("Withdraw recommendation")
        expect(planning_application.reload.status).to eq("in_assessment")

        # Check latest audit
        click_link "Application"
        click_button "Audit log"
        expect(page).to have_content("Recommendation withdrawn")
        expect(page).to have_text("Alice Aplin")
        click_link "View all audits"

        # Check audit logs
        within("#audit_#{Audit.last.id}") do
          expect(page).to have_content("Recommendation withdrawn")
          expect(page).to have_text(assessor.name)
          expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end
    end

    context "when clicking Save and come back later" do
      context "with no previous recommendations" do
        it "can create a new recommendation,saves it and come back later" do
          within(selected_govuk_tab) do
            click_link(planning_application.reference)
          end

          click_link("Check and assess")
          click_link("Make draft recommendation")
          choose "Yes"
          fill_in "State the reasons why this application is, or is not lawful.", with: "This is a public comment"
          fill_in "Provide supporting information for your manager.", with: "This is a private assessor comment"
          click_button "Save and come back later"

          planning_application.reload
          expect(planning_application.recommendations.count).to eq(1)
          expect(planning_application.public_comment).to eq("This is a public comment")
          expect(planning_application.recommendations.first.assessor_comment).to eq("This is a private assessor comment")
          expect(planning_application.decision).to eq("granted")

          click_link("Make draft recommendation")
          expect(page).to have_checked_field("Yes")
          expect(page).to have_content("This is a public comment")
          expect(page).to have_field("Provide supporting information for your manager.",
                                     with: "This is a private assessor comment")
        end
      end

      it "errors if no decision given" do
        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link("Check and assess")
        click_link("Make draft recommendation")
        click_button "Save and come back later"

        expect(page).not_to have_content("Please select Yes or No")

        expect(planning_application.status).to eq("in_assessment")
      end

      context "when assessor submits recommendation and reviewer requests changes" do
        it "displays recommendation events" do
          travel_to(Time.zone.local(2022, 8, 23, 9))

          visit(
            new_planning_application_recommendation_path(planning_application)
          )

          choose("Yes")

          fill_in(
            "State the reasons why this application is, or is not lawful.",
            with: "Application valid."
          )

          fill_in(
            "Provide supporting information for your manager.",
            with: "Requirements met."
          )

          click_button("Save and mark as complete")
          click_link("Review and submit recommendation")
          click_button("Submit recommendation")
          sign_in(reviewer)
          visit(edit_planning_application_recommendations_path(planning_application))
          choose("No (return the case for assessment)")

          expect(page).to have_text "Case currently assigned to: Alice Aplin"

          fill_in(
            "Explain to the officer why the case is being returned",
            with: "Requirements not met."
          )

          click_button("Save and mark as complete")
          click_link("Back")
          click_link("Check and assess")
          click_link("Make draft recommendation")

          events = find_all(".recommendation-event")

          within(events[0]) do
            expect(page).to have_content("Submitted recommendation")
            expect(page).to have_content("by Alice Aplin, 23 Aug 2022 at 09:00am")
            expect(page).to have_content("Requirements met.")
          end

          within(events[1]) do
            expect(page).to have_content("Recommendation queried")
            expect(page).to have_content("by Bella Brook, 23 Aug 2022 at 09:00am")
            expect(page).to have_content("Requirements not met.")
          end
        end
      end
    end

    context "when displaying documents included in the decision notice" do
      context "when there are documents" do
        let!(:decision_notice_document1) do
          create(:document, :referenced, numbers: "A", planning_application:)
        end

        let!(:decision_notice_document2) do
          create(:document, :referenced, numbers: "B", planning_application:)
        end

        let!(:non_decision_notice_document) do
          create(:document, referenced_in_decision_notice: false, numbers: "C", planning_application:)
        end

        let!(:archived_document) do
          create(:document, :referenced, :archived, numbers: "D", planning_application:)
        end

        it "displays the documents to be referenced in the decision notice" do
          visit new_planning_application_recommendation_path(planning_application)

          within("#decision-notice-documents") do
            expect(page).to have_content("Documents included in the decision notice")
            expect(page).to have_link(
              "#{decision_notice_document1.name} - A",
              href: edit_planning_application_document_path(decision_notice_document1.planning_application, decision_notice_document1.id)
            )
            expect(page).to have_link(
              "#{decision_notice_document2.name} - B",
              href: edit_planning_application_document_path(decision_notice_document2.planning_application, decision_notice_document2.id)
            )

            expect(page).not_to have_content("#{non_decision_notice_document.name} - C")
            expect(page).not_to have_content("#{archived_document.name} - D")
          end
        end
      end

      context "when there are no documents" do
        it "displays there are no documents text" do
          visit new_planning_application_recommendation_path(planning_application)

          within("#decision-notice-documents") do
            expect(page).to have_content("Documents included in the decision notice")
            expect(page).to have_content("There are no documents listed on the decision notice.")
          end
        end
      end
    end

    context "when there are assessment details" do
      let!(:summary_of_work) { create(:assessment_detail, :summary_of_work, entry: "A summary of work entry", planning_application:) }
      let!(:additional_evidence) { create(:assessment_detail, :additional_evidence, entry: "An additional evidence entry", planning_application:) }
      let!(:site_description) { create(:assessment_detail, :site_description, entry: "A site description entry", planning_application:) }
      let!(:past_applications) { create(:assessment_detail, :past_applications, entry: "An entry for planning history", additional_information: "REF123", planning_application:) }
      let!(:permitted_development_right) { create(:permitted_development_right, :removed, planning_application:) }
      let!(:immunity_detail) { create(:immunity_detail, planning_application:) }
      let!(:review_immunity_detail) { create(:review_immunity_detail, decision: "Yes", decision_reason: "no action is taken within 4 years of substantial completion for a breach of planning control consisting of operational development", immunity_detail:) }
      let!(:evidence_group1) { create(:evidence_group, start_date: "2010-05-02 12:13:41.501488206 +0000", end_date: "2015-05-02 12:13:41.501488206 +0000", missing_evidence: true, immunity_detail:) }
      let!(:evidence_group2) { create(:evidence_group, start_date: "2009-05-02 12:13:41.501488206 +0000", end_date: nil, immunity_detail:) }

      it "shows the relevant assessment details when assessing the recommendation" do
        visit new_planning_application_recommendation_path(planning_application)

        within("#constraints-section") do
          expect(page).to have_content("Constraints including Article 4 direction(s)")
          expect(page).to have_content("Conservation area Listed building")
          expect(page).to have_link("Edit constraints")
        end

        within("#past-applications-section") do
          expect(page).to have_content("Planning history")
          expect(page).to have_content("REF123")
          expect(page).to have_content("An entry for planning history")
        end

        within("#immunity-section") do
          expect(page).to have_content("Immunity from enforcement")
          expect(page).to have_content("Evidence cover: 02/05/2009 to 02/05/2015")
          expect(page).to have_content("Missing evidence (gap in time): Yes")
          expect(page).to have_content("no action is taken within 4 years of substantial completion for a breach of planning control consisting of operational development")
        end

        within("#summary-of-works-section") do
          expect(page).to have_content("Summary of works")
          expect(page).to have_content("A summary of work entry")
        end

        within("#site-description-section") do
          expect(page).to have_content("Location description")
          expect(page).to have_content("A site description entry")
        end

        within("#additional-evidence-section") do
          expect(page).to have_content("Summary of additional evidence")
          expect(page).to have_content("An additional evidence entry")
        end

        within("#permitted-development-rights-section") do
          expect(page).to have_content("Have the permitted development rights relevant for this application been removed?")
          expect(page).to have_content("Yes")
          expect(page).to have_content("Removal reason")
        end
      end

      it "does not show additional evidence when reviewing and submitting the recommendation" do
        visit new_planning_application_recommendation_path(planning_application)
        choose "Yes"

        fill_in "State the reasons why this application is, or is not lawful.", with: "This is a public comment"
        fill_in "Provide supporting information for your manager.", with: "This is a private assessor comment"
        click_button "Save and mark as complete"

        visit submit_recommendation_planning_application_path(planning_application)
        expect(page).to have_css("#constraints-section")
        expect(page).to have_css("#past-applications-section")
        expect(page).to have_css("#summary-of-works-section")
        expect(page).to have_css("#site-description-section")
        expect(page).to have_css("#permitted-development-rights-section")

        expect(page).not_to have_css("#additional-evidence-section")
        expect(page).not_to have_content("Additional evidence")
      end
    end

    context "when there are post-validation requests" do
      before { freeze_time }

      context "with an open red line boundary request" do
        let!(:post_validation_red_line_boundary_change_validation_request) do
          create(:red_line_boundary_change_validation_request, :post_validation, :open, planning_application:)
        end

        it "displays a warning message with a link to the post validation requests table" do
          visit new_planning_application_recommendation_path(planning_application)

          within(".moj-banner__message") do
            expect(page).to have_content("There are outstanding change requests (last request #{Time.current.to_fs}")
            expect(page).to have_link(
              "View all requests", href: post_validation_requests_planning_application_validation_requests_path(planning_application)
            )
          end
        end
      end

      context "with an open description change request" do
        let!(:post_description_change_validation_request) do
          create(:description_change_validation_request, :post_validation, :open, planning_application:)
        end

        it "displays a warning message with a link to the post validation requests table" do
          visit new_planning_application_recommendation_path(planning_application)

          within(".moj-banner__message") do
            expect(page).to have_content("There are outstanding change requests (last request #{Time.current.to_fs}")
            expect(page).to have_link(
              "View all requests", href: post_validation_requests_planning_application_validation_requests_path(planning_application)
            )
          end
        end
      end

      context "with a closed change request" do
        let!(:post_validation_red_line_boundary_change_validation_request) do
          create(:red_line_boundary_change_validation_request, :post_validation, :closed, planning_application:)
        end

        it "does not display any warning message" do
          visit new_planning_application_recommendation_path(planning_application)

          expect(page).not_to have_css(".moj-banner__message")
        end
      end

      context "with no request" do
        it "does not display any warning message" do
          visit new_planning_application_recommendation_path(planning_application)

          expect(page).not_to have_css(".moj-banner__message")
        end
      end
    end
  end

  context "when application type is prior approval" do
    let!(:planning_application) do
      travel_to("2022-01-01") do
        create(
          :planning_application,
          :in_assessment,
          :prior_approval,
          local_authority: default_local_authority
        )
      end
    end

    before do
      sign_in assessor
      visit planning_applications_path
    end

    context "when clicking Save and mark as complete" do
      context "with no previous recommendations" do
        it "can create a new recommendation, edit it, and submit it" do
          within(selected_govuk_tab) do
            click_link(planning_application.reference)
          end

          click_link("Check and assess")
          click_link("Make draft recommendation")

          choose "Prior approval required and approved"

          fill_in "State the reasons for your recommendation.", with: "This is a public comment"
          fill_in "Provide supporting information for your manager.", with: "This is a private assessor comment"
          click_button "Save and mark as complete"

          planning_application.reload
          expect(planning_application.recommendations.count).to eq(1)
          expect(planning_application.public_comment).to eq("This is a public comment")
          expect(planning_application.recommendations.first.assessor_comment).to eq("This is a private assessor comment")
          expect(planning_application.decision).to eq("granted")

          click_link("Review and submit recommendation")
          expect(page).to have_content("Prior approval required and approved")

          click_link("Back")

          click_link("Check and assess")
          click_link("Make draft recommendation")

          expect(page).to have_checked_field("Prior approval required and approved")
          expect(page).not_to have_checked_field("Prior approval not required")
          expect(page).not_to have_checked_field("Prior approval required and refused")

          expect(page).to have_field("Provide supporting information for your manager.",
                                     with: "This is a private assessor comment")
          choose "Prior approval not required"
          fill_in "State the reasons for your recommendation.", with: "This is a new public comment"
          fill_in "Provide supporting information for your manager.", with: "Edited private assessor comment"
          click_button "Update assessment"
          planning_application.reload

          expect(planning_application.recommendations.count).to eq(1)
          expect(planning_application.recommendations.first.assessor_comment).to eq("Edited private assessor comment")
          expect(planning_application.decision).to eq("granted_not_required")
          expect(planning_application.public_comment).to eq("This is a new public comment")

          click_link "Review and submit recommendation"
          expect(page).to have_content("Prior approval not required")

          click_link("Back")

          click_link("Check and assess")
          click_link("Make draft recommendation")

          expect(page).not_to have_checked_field("Prior approval required and approved")
          expect(page).to have_checked_field("Prior approval not required")
          expect(page).not_to have_checked_field("Prior approval required and refused")

          expect(page).to have_field("Provide supporting information for your manager.",
                                     with: "Edited private assessor comment")
          choose "Prior approval required and refused"
          fill_in "State the reasons for your recommendation.", with: "This is a new public comment"
          fill_in "Provide supporting information for your manager.", with: "Edited private assessor comment"
          click_button "Update assessment"
          planning_application.reload

          expect(planning_application.recommendations.count).to eq(1)
          expect(planning_application.recommendations.first.assessor_comment).to eq("Edited private assessor comment")
          expect(planning_application.decision).to eq("refused")
          expect(planning_application.public_comment).to eq("This is a new public comment")

          click_link "Review and submit recommendation"
          expect(page).to have_content("Prior approval required and refused")

          expect(page).not_to have_content("We certify that on the date of the application")
          expect(page).not_to have_content("not lawful")
          expect(page).to have_content("aggrieved")

          expect(page).to have_content("If you agree with this decision notice, submit it to your line manager.")

          click_button "Submit recommendation"

          expect(page).to have_content("Recommendation was successfully submitted.")

          within "#assess-section" do
            click_link "Check and assess"
          end

          within "#complete-assessment-tasks" do
            expect(list_item("Make draft recommendation")).to have_content("Completed")
          end

          perform_enqueued_jobs
          update_notification = ActionMailer::Base.deliveries.last

          expect(update_notification.to).to contain_exactly(
            "reviewers@example.com"
          )

          expect(update_notification.subject).to eq(
            "BoPS case PlanX-22-00100-PA has a new update"
          )

          planning_application.reload
          expect(planning_application.status).to eq("awaiting_determination")

          visit planning_application_path(planning_application)
          click_link "View recommendation"
          expect(page).to have_text("Recommendations submitted by #{planning_application.recommendations.first.assessor.name}")

          click_link "Back"

          click_button "Audit log"
          click_link "View all audits"

          expect(page).to have_text("Recommendation submitted")
          expect(page).to have_text(assessor.name)
          expect(page).to have_text("Assessor comment: Edited private assessor comment")
          expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end
    end
  end
end
