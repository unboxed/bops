# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Reviewing", type: :system do
  context "as a reviewer" do
    # Look at an application that has had some assessment work done by the assessor
    let(:policy_evaluation) { create(:policy_evaluation, :met) }
    let(:assessor) { create :user, :assessor }
    let(:applicant) { create :applicant, email: "bigplans@example.com" }
    let!(:planning_application) do
      create :planning_application,
       :awaiting_determination,
       policy_evaluation: policy_evaluation,
       assessor_decision: assessor_decision,
       applicant: applicant
    end

    before do
      sign_in users(:reviewer)
      visit root_path
    end

    context "with a granted assessor_decision" do
      let(:assessor_decision) { create :decision, :granted, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is granted.")
        expect(page).not_to have_content("The following policy requirement(s) have not been met:")
        expect(page).not_to have_content("This has been refused.")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Review the recommendation"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("Yes")).to be_checked
        end
        click_button "Save"

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("granted")
        expect(page).not_to have_content("The proposal does not comply with:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        mail = ActionMailer::Base.deliveries.first

        expect(mail.to.first).to eq "bigplans@example.com"
        expect(mail.subject).to eq("Certificate of Lawfulness: granted")
        expect(mail.body.encoded).to match("Certificate of lawfulness of proposed use or development: granted.")

        within(:assessment_step, "Publish the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting manager's determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Determined"
        within("#determined") do
          expect(page).to have_link planning_application.reference
        end

        id = planning_application.id

        # TODO: Replace this with a check for state in the read-only determined decision
        # notice when we implement it
        planning_application = PlanningApplication.find_by(id: id)

        expect(planning_application.determined_at).to be_within(5.seconds).of(Time.current)
      end

      scenario "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is granted.")
        expect(page).not_to have_content("The following policy requirement(s) have not been met:")
        expect(page).not_to have_content("This has been refused.")

        choose "No"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Review the recommendation"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("No")).to be_checked
        end
        click_button "Save"

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("refused")
        expect(page).not_to have_content("The proposal does not comply with:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting manager's determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Determined"
        within("#determined") do
          expect(page).to have_link planning_application.reference
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
            api_key: "fake__notarealkey-00000000-0000-0000-0000-000000000000-00000000-0000-0000-0000-000000000000"
          }

          example.run

          ActionMailer::Base.delivery_method = delivery_method
          ActionMailer::Base.notify_settings = notify_settings
        end

        scenario "it displays a flash message" do
          stub_request(:post, notify_url).to_return(
            status: 404
          )

          within("#awaiting_determination") do
            click_link planning_application.reference
          end

          click_link "Review the recommendation"
          choose "Yes"
          click_button "Save"

          click_link "Publish the recommendation"
          click_button "Determine application"

          expect(page).to have_content("The Decision Notice cannot be sent. Please try again later.")
        end
      end

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end

    context "with a refused assessor_decision without a comment" do
      let(:assessor_decision) { create :decision, :refused, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is refused")
        expect(page).not_to have_content("and added this comment:")
        expect(page).not_to have_content("This has been refused.")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_completed_tag
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
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting manager's determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Determined"
        within("#determined") do
          expect(page).to have_link planning_application.reference
        end
      end

      scenario "disagrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is refused")
        expect(page).not_to have_content("and added this comment:")
        expect(page).not_to have_content("This has been refused.")

        choose "No"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Review the recommendation"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("No")).to be_checked
        end
        click_button "Save"

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("granted")
        expect(page).not_to have_content("Reason why use or operations would not have been LAWFUL:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting manager's determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Determined"
        within("#determined") do
          expect(page).to have_link planning_application.reference
        end
      end

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end

    context "with a refused assessor_decision with a comment" do
      let(:assessor_decision) { create :decision, :refused_with_comment, user: assessor }

      scenario "agrees with assessor's decision" do
        # Check that the application is no longer in awaiting determination
        within("#awaiting_determination") do
          click_link planning_application.reference
        end

        expect(page).not_to have_link("Publish the recommendation")

        click_link "Review the recommendation"

        expect(page).to have_content("The planning officer recommends that the application is refused.")
        expect(page).to have_content("The following policy requirement(s) have not been met:")

        choose "Yes"
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_completed_tag
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

        click_button "Determine application"

        within(:assessment_step, "Publish the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting manager's determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Determined"
        within("#determined") do
          expect(page).to have_link planning_application.reference
        end
      end

      scenario "disagrees with assessor's decision" do
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
        click_button "Save"

        within(:assessment_step, "Review the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Review the recommendation"

        # Expect the saved state to be shown in the form
        within(find("form.decision")) do
          expect(page.find_field("No")).to be_checked
        end
        click_button "Save"

        click_link "Publish the recommendation"

        expect(page).to have_content("The following decision notice was created based on the planning officer's recommendation and comment. Please review and publish it.")
        expect(page).to have_content("granted")
        expect(page).not_to have_content("The proposal does not comply with:")
        expect(page).not_to have_content("This has been refused.")

        click_button "Determine application"

        within(:assessment_step, "Publish the recommendation") do
          expect(page).to have_completed_tag
        end

        click_link "Home"

        # Check that the application is no longer in awaiting determination
        click_link "Awaiting manager's determination"
        within("#awaiting_determination") do
          expect(page).not_to have_link planning_application.reference
        end

        # Check that the application is now in determined
        click_link "Determined"
        within("#determined") do
          expect(page).to have_link planning_application.reference
        end
      end

      include_examples "reviewer assignment"
      include_examples "reviewer decision error message"
    end
  end

  context "as an admin" do
    let(:assessor) { create :user, :assessor }
    let(:assessor_decision) { create :decision, :granted, user: assessor }

    let!(:planning_application) do
      create :planning_application, assessor_decision: assessor_decision
    end

    before do
      sign_in users(:admin)

      visit root_path
    end

    scenario "Assessment editing" do
      # TODO: Define admin actions on a planning application further and test them

      click_link planning_application.reference

      expect(page).to have_link "Assess the proposal"

      within(:assessment_step, "Assess the proposal") do
        expect(page).to have_completed_tag
      end
    end
  end
end
