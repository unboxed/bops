# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
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

  let!(:planning_application) do
    create(
      :planning_application,
      local_authority: default_local_authority,
      created_at: DateTime.new(2022, 1, 1),
      public_comment: nil
    )
  end

  before do
    sign_in assessor
    visit root_path
  end

  context "when clicking Save and mark as complete" do
    context "with no previous recommendations" do
      it "can create a new recommendation, edit it, and submit it" do
        travel_to(Date.new(2022))
        click_link "In assessment"

        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link "Assess recommendation"
        choose "Yes"
        fill_in "State the reasons why this application is, or is not lawful.", with: "This is a public comment"
        fill_in "Please provide supporting information for your manager.", with: "This is a private assessor comment"
        click_button "Save and mark as complete"

        planning_application.reload
        expect(planning_application.recommendations.count).to eq(1)
        expect(planning_application.public_comment).to eq("This is a public comment")
        expect(planning_application.recommendations.first.assessor_comment).to eq("This is a private assessor comment")
        expect(planning_application.decision).to eq("granted")

        click_link "Assess recommendation"
        expect(page).to have_checked_field("Yes")
        expect(page).to have_field("Please provide supporting information for your manager.",
                                   with: "This is a private assessor comment")
        choose "No"
        fill_in "State the reasons why this application is, or is not lawful.", with: "This is a new public comment"
        fill_in "Please provide supporting information for your manager.", with: "Edited private assessor comment"
        click_button "Update assessment"
        planning_application.reload

        expect(planning_application.recommendations.count).to eq(1)
        expect(planning_application.recommendations.first.assessor_comment).to eq("Edited private assessor comment")
        expect(planning_application.decision).to eq("refused")
        expect(planning_application.public_comment).to eq("This is a new public comment")

        click_link "Submit recommendation"

        expect(page).to have_content("We certify that on the date of the application")
        expect(page).to have_content("not lawful")
        expect(page).to have_content("aggrieved")

        click_button "Submit to manager"

        expect(page).to have_content("Recommendation was successfully submitted.")

        perform_enqueued_jobs
        update_notification = ActionMailer::Base.deliveries.last

        expect(update_notification.to).to contain_exactly(
          "reviewers@example.com"
        )

        expect(update_notification.subject).to eq(
          "BoPS case RIPA-22-00100-LDCP has a new update"
        )

        planning_application.reload
        expect(planning_application.status).to eq("awaiting_determination")
        click_link "View recommendation"
        expect(page).to have_text("Recommendations submitted by #{planning_application.recommendations.first.assessor.name}")

        click_link "Back"

        click_button "Audit log"
        click_link "View all audits"

        expect(page).to have_text("Recommendation submitted")
        expect(page).to have_text(assessor.name)
        expect(page).to have_text("Assessor comment: Edited private assessor comment")
        expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))

        travel_back
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
      create :planning_application, :awaiting_correction, local_authority: default_local_authority
    end

    let!(:recommendation) do
      create :recommendation, :reviewed, planning_application: planning_application,
                                         reviewer_comment: "I disagree", assessor_comment: "This looks good"
    end

    it "displays the previous recommendations" do
      click_link "In assessment"

      within(selected_govuk_tab) do
        click_link(planning_application.reference)
      end

      click_link "Assess recommendation"

      within ".recommendations" do
        expect(page).to have_content("I disagree")
        expect(page).to have_content("This looks good")
      end

      choose "Yes"
      fill_in "State the reasons why this application is, or is not lawful.",
              with: "This is so granted and GDPO everything"
      fill_in "Please provide supporting information for your manager.", with: "This is a private assessor comment"
      click_button "Update assessment"

      planning_application.reload
      expect(planning_application.recommendations.count).to eq(2)
      expect(planning_application.public_comment).to eq("This is so granted and GDPO everything")
      expect(planning_application.recommendations.last.assessor_comment).to eq("This is a private assessor comment")
      expect(planning_application.decision).to eq("granted")

      click_link "Assess recommendation"

      within ".recommendations" do
        expect(page).to have_content("I disagree")
        expect(page).to have_content("This looks good")
        expect(page).not_to have_content("This is a private assessor comment")
      end

      expect(page).to have_checked_field("Yes")
      expect(page).to have_field("Please provide supporting information for your manager.",
                                 with: "This is a private assessor comment")
    end
  end

  context "when submitting a recommendation" do
    it "can only be submitted when a planning application is in assessment" do
      click_link("In assessment")

      within(selected_govuk_tab) do
        click_link(planning_application.reference)
      end

      click_link("Assess recommendation")

      expect(page).to have_content(
        "No legislation assessed for this application."
      )

      choose("Yes")
      fill_in("State the reasons why this application is, or is not lawful.", with: "This is a public comment")
      fill_in("Please provide supporting information for your manager.", with: "This is a private assessor comment")
      click_button("Save and mark as complete")

      click_link("Submit recommendation")
      click_button("Submit to manager")

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
      within("#latest-audit") do
        expect(page).to have_content("Recommendation submitted")
        expect(page).to have_text("Assessor comment: This is a private assessor comment")
        expect(page).to have_text(assessor.name)
        expect(page).to have_text(Audit.last.created_at.strftime("%H:%M"))

        click_link "View all audits"
      end

      # Check audit logs
      within("#audit_#{Audit.last.id}") do
        expect(page).to have_content("Recommendation submitted")
        expect(page).to have_text("Assessor comment: This is a private assessor comment")
        expect(page).to have_text(assessor.name)
        expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
      end
    end

    context "when there are open post validation requests" do
      let!(:planning_application) { create(:in_assessment_planning_application, local_authority: default_local_authority) }
      let!(:red_line_boundary_change_validation_request) { create(:red_line_boundary_change_validation_request, :open, :post_validation, planning_application: planning_application) }

      it "prevents me from submitting the planning application" do
        click_link("In assessment")

        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link("Assess recommendation")
        choose("Yes")
        fill_in("State the reasons why this application is, or is not lawful.", with: "This is a public comment")
        fill_in("Please provide supporting information for your manager.", with: "This is a private assessor comment")
        click_button("Save and mark as complete")

        click_link("Submit recommendation")
        click_button("Submit to manager")

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
      click_link("Awaiting determination")

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
      expect(page).to have_button("Submit to manager")
      expect(page).not_to have_button("Withdraw recommendation")
      expect(planning_application.reload.status).to eq("in_assessment")

      # Check latest audit
      click_button "Audit log"
      within("#latest-audit") do
        expect(page).to have_content("Recommendation withdrawn")
        expect(page).to have_text(assessor.name)
        expect(page).to have_text(Audit.last.created_at.strftime("%H:%M"))

        click_link "View all audits"
      end

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
        click_link "In assessment"

        within(selected_govuk_tab) do
          click_link(planning_application.reference)
        end

        click_link "Assess recommendation"
        choose "Yes"
        fill_in "State the reasons why this application is, or is not lawful.", with: "This is a public comment"
        fill_in "Please provide supporting information for your manager.", with: "This is a private assessor comment"
        click_button "Save and come back later"

        planning_application.reload
        expect(planning_application.recommendations.count).to eq(1)
        expect(planning_application.public_comment).to eq("This is a public comment")
        expect(planning_application.recommendations.first.assessor_comment).to eq("This is a private assessor comment")
        expect(planning_application.decision).to eq("granted")

        click_link "Assess recommendation"
        expect(page).to have_checked_field("Yes")
        expect(page).to have_content("This is a public comment")
        expect(page).to have_field("Please provide supporting information for your manager.",
                                   with: "This is a private assessor comment")
      end
    end

    it "errors if no decision given" do
      click_link "In assessment"

      within(selected_govuk_tab) do
        click_link(planning_application.reference)
      end

      click_link "Assess recommendation"
      click_button "Save and come back later"

      expect(page).not_to have_content("Please select Yes or No")

      expect(planning_application.status).to eq("in_assessment")
    end

    context "when officer assesses legislation" do
      it "shows assessed legislation on recommendation page" do
        visit(planning_application_path(planning_application))
        click_link("Check and assess")
        click_link("Add assessment area")
        choose("Part 1 - Development within the curtilage of a dwellinghouse")
        click_button("Continue")
        check("Class D - porches")
        click_button("Add classes")
        click_link("Part 1, Class D")
        choose("policy_class_policies_attributes_0_status_complies")
        choose("policy_class_policies_attributes_1_status_complies")
        choose("policy_class_policies_attributes_2_status_complies")
        choose("policy_class_policies_attributes_3_status_complies")
        choose("policy_class_policies_attributes_4_status_to_be_determined")
        click_button("Save assessments")
        click_link("Assess recommendation")

        expect(page).to have_content("To be determined")

        click_link("Part 1, Class D - porches")
        choose("policy_class_policies_attributes_4_status_does_not_comply")
        click_button("Save assessments")
        click_link("Assess recommendation")

        expect(page).to have_content("Does not comply")

        expect(page).to have_content(
          "Development is not permitted by Class D if the dwellinghouse is built under Part 20 of this Schedule (construction of new dwellinghouses)"
        )

        click_link("Part 1, Class D - porches")
        choose("policy_class_policies_attributes_4_status_complies")
        click_button("Save assessments")
        click_link("Assess recommendation")

        expect(page).to have_content("Complies")
      end
    end

    context "when assessor submits recommendation and reviewer requests changes" do
      let(:reviewer) do
        create(
          :user,
          :reviewer,
          local_authority: default_local_authority,
          name: "Bella Brook"
        )
      end

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
          "Please provide supporting information for your manager.",
          with: "Requirements met."
        )

        click_button("Save and mark as complete")
        click_link("Submit recommendation")
        click_button("Submit to manager")
        sign_in(reviewer)
        visit(edit_planning_application_recommendations_path(planning_application))
        find("#recommendation_challenged_true").click
        fill_in("Review comment", with: "Requirements not met.")
        click_button("Save")
        click_link("Assess recommendation")

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
        create(:document, :referenced, numbers: "A", planning_application: planning_application)
      end

      let!(:decision_notice_document2) do
        create(:document, :referenced, numbers: "B", planning_application: planning_application)
      end

      let!(:non_decision_notice_document) do
        create(:document, referenced_in_decision_notice: false, numbers: "C", planning_application: planning_application)
      end

      let!(:archived_document) do
        create(:document, :referenced, :archived, numbers: "D", planning_application: planning_application)
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
          expect(page).to have_content("No documents listed on decision notice.")
        end
      end
    end
  end
end
