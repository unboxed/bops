# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Reviewing", type: :system do
  context "as a reviewer" do
    # Look at an application that has had some assessment work done by the assessor
    let(:local_authority) { create :local_authority }
    let(:policy_evaluation) { create(:policy_evaluation, :met) }
    let!(:planning_application) do
      create :planning_application,
             :awaiting_determination,
             policy_evaluation: policy_evaluation,
             local_authority: local_authority,
             assessor_decision: assessor_decision,
             applicant_email: "bigplans@example.com"
    end
    let(:assessor) { create :user, :assessor, local_authority: local_authority }
    let(:reviewer) { create :user, :reviewer, local_authority: local_authority }

    before do
      sign_in reviewer
      visit root_path
    end

    context "with a granted assessor_decision" do
      let(:assessor_decision) { create :decision, :granted, user: assessor }

      it "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).to have_content("Determine the proposal")
        expect(page).to have_link("Review the recommendation")
        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is granted.")
        expect(page).not_to have_content("The following policy requirement(s) have not been met:")
        expect(page).not_to have_content("This has been refused.")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_content("Completed")
        end

        click_link "Review the recommendation"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        expect(page).to have_content("Determine the proposal")
        expect(page).to have_link("Review the recommendation")
        expect(page).to have_link("Publish the recommendation")

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("granted")
        expect(page).to have_content("proposed")
        expect(page).to have_content("Proposed")
        expect(page).not_to have_content("The proposal does not comply with:")
        expect(page).not_to have_content("This has been refused.")

        expect(page).not_to have_content("The officer has submitted the following comment for you:")
        expect(page).not_to have_content("This is a private comment")

        click_button "Determine application"

        mail = ActionMailer::Base.deliveries.first

        expect(mail.to.first).to eq "bigplans@example.com"
        expect(mail.subject).to eq("Certificate of Lawfulness: granted")

        expect(page).to have_content("View the application")
        expect(page).to have_link("View the assessment")
        expect(page).to have_link("View the decision notice")

        within(:assessment_step, "View the decision notice") do
          expect(page).to have_content("Completed")
        end

        click_link "View the assessment"
        click_link "Back"

        click_link "View the decision notice"
        click_link "Back"

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Closed"
        within("#closed") do
          expect(page).to have_link planning_application.reference
        end

        id = planning_application.id

        # TODO: Replace this with a check for state in the read-only determined decision
        # notice when we implement it
        planning_application = PlanningApplication.find_by(id: id)

        expect(planning_application.determined_at).to be_within(5.seconds).of(Time.zone.now)
      end

      it "agrees with assessor's decision when proposed work has been completed" do
        planning_application.update!(work_status: "existing")

        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).to have_content("Determine the proposal")
        expect(page).to have_link("Review the recommendation")
        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is granted.")
        expect(page).not_to have_content("The following policy requirement(s) have not been met:")
        expect(page).not_to have_content("This has been refused.")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_content("Completed")
        end

        click_link "Review the recommendation"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        expect(page).to have_content("Determine the proposal")
        expect(page).to have_link("Review the recommendation")
        expect(page).to have_link("Publish the recommendation")

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("granted")
        expect(page).to have_content("existing")
        expect(page).not_to have_content("The proposal does not comply with:")
        expect(page).not_to have_content("This has been refused.")

        expect(page).not_to have_content("The officer has submitted the following comment for you:")
        expect(page).not_to have_content("This is a private comment")

        click_button "Determine application"

        mail = ActionMailer::Base.deliveries.first

        expect(mail.to.first).to eq "bigplans@example.com"
        expect(mail.subject).to eq("Certificate of Lawfulness: granted")

        expect(page).to have_content("View the application")
        expect(page).to have_link("View the assessment")
        expect(page).to have_link("View the decision notice")

        within(:assessment_step, "View the decision notice") do
          expect(page).to have_content("Completed")
        end

        click_link "View the assessment"
        click_link "Back"

        click_link "View the decision notice"
        click_link "Back"

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Closed"
        within("#closed") do
          expect(page).to have_link planning_application.reference
        end

        # Check that documents validation form is removed
        click_link planning_application.reference
        expect(page).not_to have_content("Are the documents valid?")
      end

      it "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is granted.")
        expect(page).not_to have_content("The following policy requirement(s) have not been met:")
        expect(page).not_to have_content("This has been refused.")

        expect(page).not_to have_content("The officer has submitted the following comment for you:")
        expect(page).not_to have_content("This is a private comment")

        choose "No"
        fill_in "private_comment", with: "I don't agree"

        click_button "Save"

        expect(page).not_to have_css("#determine-the-application-completed")

        expect(page).not_to have_link("Review the recommendation")
        expect(page).not_to have_text("Review the recommendation")

        expect(page).to have_link("Reassess the proposal")
        expect(page).to have_text("Resubmit the recommendation")

        click_link "Reassess the proposal"
        click_link "Back"

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in corrections requested
        click_link "Corrections requested"
        within("#awaiting_correction") do
          expect(page).to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Closed"
        within("#closed") do
          expect(page).not_to have_link planning_application.reference
        end
      end

      context "when the applicant decision notice email can't be sent" do
        let(:notify_url) do
          "https://api.notifications.service.gov.uk/v2/notifications/email"
        end

        around do |example|
          delivery_method = ActionMailer::Base.delivery_method
          notify_settings = ActionMailer::Base.notify_settings

          ActionMailer::Base.delivery_method = :notify
          ActionMailer::Base.notify_settings = {
            api_key: "fake__notarealkey-00000000-0000-0000-0000-000000000000-00000000-0000-0000-0000-000000000000",
          }

          example.run

          ActionMailer::Base.delivery_method = delivery_method
          ActionMailer::Base.notify_settings = notify_settings
        end

        it "displays a flash message" do
          stub_request(:post, notify_url).to_return(
            status: 404,
          )

          within("#awaiting_determination") do
            click_link planning_application.reference
          end

          click_link "Review the recommendation"
          choose "Yes"
          click_button "Save"

          click_link "Publish the recommendation"
          click_button "Determine application"

          expect(page).to have_content("The email cannot be sent. Please try again later.")
        end
      end

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end

    context "with a refused assessor_decision" do
      let(:assessor_decision) { create :decision, :refused_with_comment, user: assessor }

      it "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is refused.")
        expect(page).to have_content("The following policy requirement(s) have not been met:")
        expect(page).to have_content("This has been refused.")

        expect(page).not_to have_content("The officer has submitted the following comment for you:")
        expect(page).not_to have_content("This is a private comment")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_content("Completed")
        end

        click_link "Review the recommendation"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("refused")
        expect(page).to have_content("The proposal does not comply with:")
        expect(page).to have_content("This has been refused.")
        expect(page).not_to have_content("This is a private comment")

        click_button "Determine application"

        within(:assessment_step, "View the decision notice") do
          expect(page).to have_content("Completed")
        end

        expect(page).to have_link("View the assessment")
        expect(page).to have_link("View the decision notice")

        click_link "View the assessment"
        click_link "Back"

        click_link "View the decision notice"
        click_link "Back"

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Closed"
        within("#closed") do
          expect(page).to have_link planning_application.reference
        end
      end

      it "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is refused.")
        expect(page).to have_content("The following policy requirement(s) have not been met:")
        expect(page).to have_content("This has been refused.")

        choose "No"
        fill_in "private_comment", with: "I don't agree"

        click_button "Save"

        expect(page).not_to have_css("#determine-the-application-completed")

        expect(page).not_to have_link("Review the recommendation")
        expect(page).not_to have_text("Review the recommendation")

        expect(page).to have_link("Reassess the proposal")
        expect(page).to have_text("Resubmit the recommendation")

        click_link "Reassess the proposal"
        click_link "Back"

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in corrections requested
        click_link "Corrections requested"
        within("#awaiting_correction") do
          expect(page).to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Closed"
        within("#closed") do
          expect(page).not_to have_link planning_application.reference
        end
      end

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end

    context "with a refused assessor_decision with private_comment" do
      let(:assessor_decision) { create :decision, :refused_with_public_and_private_comment, user: assessor }

      it "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is refused.")
        expect(page).to have_content("The following policy requirement(s) have not been met:")

        expect(page).to have_content("The officer has submitted the following comment for you:")
        expect(page).to have_content("This is a private comment")

        expect(page).not_to have_content("Are the documents valid?")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_content("Completed")
        end

        click_link "Review the recommendation"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("refused")
        expect(page).to have_content("The proposal does not comply with:")
        expect(page).to have_content("This has been refused.")

        expect(page).not_to have_content("The officer has submitted the following comment for you:")
        expect(page).not_to have_content("This is a private comment")

        click_button "Determine application"

        within(:assessment_step, "View the decision notice") do
          expect(page).to have_content("Completed")
        end

        expect(page).to have_link("View the assessment")
        expect(page).to have_link("View the decision notice")

        click_link "View the assessment"
        click_link "Back"

        click_link "View the decision notice"
        click_link "Back"

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Closed"
        within("#closed") do
          expect(page).to have_link planning_application.reference
        end
      end

      it "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is refused.")
        expect(page).to have_content("The following policy requirement(s) have not been met:")
        expect(page).to have_content("This has been refused.")

        choose "No"
        fill_in "private_comment", with: "I don't agree"

        click_button "Save"

        expect(page).not_to have_css("#determine-the-application-completed")

        expect(page).not_to have_link("Review the recommendation")
        expect(page).not_to have_text("Review the recommendation")

        expect(page).to have_link("Reassess the proposal")
        expect(page).to have_text("Resubmit the recommendation")

        click_link "Reassess the proposal"
        click_link "Back"

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in corrections requested
        click_link "Corrections requested"
        within("#awaiting_correction") do
          expect(page).to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Closed"
        within("#closed") do
          expect(page).not_to have_link planning_application.reference
        end
      end

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end
  end
end
