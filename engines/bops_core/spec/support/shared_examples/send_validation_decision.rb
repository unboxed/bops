# frozen_string_literal: true

RSpec.shared_examples "send validation decision task", :capybara do |application_type|
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/review/send-validation-decision") }
  let(:publishable?) { planning_application.publishable? }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/validation"
  end

  it "allows the application to be made valid" do
    within :sidebar do
      click_link "Send validation decision"
    end

    expect(page).to have_selector("h1", text: "Send validation decision")
    expect(page).to have_content("The application has not been marked as valid or invalid yet.")
    expect(task).to be_not_started

    if publishable?
      within_fieldset "Publish application on BOPS Public Portal?" do
        choose "Yes"
      end
    end

    click_button "Mark the application as valid"
    expect(page).to have_content("An email notification has been sent to the applicant.")
    expect(page).to have_content("The application is now ready for consultation and assessment")

    click_link "Check and validate"

    within :sidebar do
      expect(page).to have_selector("h3", text: "Validation tasks")

      click_link "Send validation decision"
    end

    expect(page).to have_selector("h1", text: "Send validation decision")
    expect(page).to have_content("The application is marked as valid and cannot be marked as invalid.")

    expect(task.reload).to be_completed
    expect(planning_application.reload).to be_valid

    if publishable?
      expect(planning_application).to be_make_public
    end
  end

  context "when there are outstanding validation requests" do
    let!(:validation_request) do
      create(
        :other_change_validation_request,
        planning_application: planning_application,
        state: "pending",
        created_at: 7.days.ago
      )
    end

    it "allows the application to be marked as invalid with outstanding validation requests" do
      within :sidebar do
        click_link "Send validation decision"
      end

      expect(page).to have_selector("h1", text: "Send validation decision")
      expect(page).to have_content("You have marked items as invalid, so you cannot validate this application.")
      expect(task).to be_not_started

      click_button "Mark the application as invalid"
      expect(page).to have_content("An email notification has been sent to the applicant.")
      expect(page).to have_content("The application is now ready for consultation and assessment.")

      click_link "Check and validate"

      within :sidebar do
        expect(page).to have_selector("h3", text: "Validation tasks")

        click_link "Send validation decision"
      end

      expect(page).to have_selector("h1", text: "Send validation decision")
      expect(page).to have_content("The application is marked as invalid.")
      expect(task.reload).to be_completed
      expect(planning_application.reload.status).to eq("invalidated")

      click_link "View existing requests"
      expect(page).to have_current_path(%r{/check-and-validate/review/review-validation-requests})
      expect(page).to have_content("Review validation requests")

      click_link "View and update"
      click_link "Cancel request"
      fill_in "Explain to the applicant why this request is being cancelled", with: "No longer needed"
      click_button "Confirm cancellation"
      expect(page).to have_content("Change request successfully cancelled.")

      within :sidebar do
        click_link "Send validation decision"
      end

      expect(page).to have_selector("h1", text: "Send validation decision")
      expect(page).to have_content("Once the application has been checked and all validation requests resolved, mark the application as valid.")

      if publishable?
        within_fieldset "Publish application on BOPS Public Portal?" do
          choose "Yes"
        end
      end

      click_button "Mark the application as valid"
      expect(page).to have_content("Validation decision sent")

      click_link "Check and validate"

      within :sidebar do
        click_link "Send validation decision"
      end

      expect(page).to have_selector("h1", text: "Send validation decision")
      expect(page).to have_content("The application is marked as valid and cannot be marked as invalid.")
      expect(task.reload).to be_completed
      expect(planning_application.reload).to be_valid

      if publishable?
        expect(planning_application).to be_make_public
      end
    end

    it "hides the validate button when there are unresolved validation requests" do
      within :sidebar do
        click_link "Send validation decision"
      end

      click_button "Mark the application as invalid"
      expect(page).to have_content("Validation decision sent")

      click_link "Check and validate"

      within :sidebar do
        click_link "Send validation decision"
      end

      expect(page).to have_content("The application is marked as invalid.")
      expect(planning_application.reload.status).to eq("invalidated")

      # The validation request is now open after invalidation
      expect(validation_request.reload.state).to eq("open")

      within :sidebar do
        click_link "Send validation decision"
      end

      expect(page).to have_content("There are 1 unresolved validation request")
      expect(page).to have_content("All validation requests must be resolved or cancelled before the application can be marked as valid.")
      expect(page).not_to have_button("Mark the application as valid")
    end
  end
end
