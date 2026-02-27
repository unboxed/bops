# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check fee task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:proposal_details) do
    [
      {
        "question" => "Planning Pre-Application Advice Services",
        "responses" => [{"value" => "Householder (£100)"}],
        "metadata" => {}
      }
    ]
  end
  let(:planning_application) { create(:planning_application, :pre_application, :not_started, local_authority:, proposal_details:) }

  it_behaves_like "check fee task", :pre_application

  describe "pre-application specific features" do
    let(:user) { create(:user, local_authority:) }
    let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/check-application-details/check-fee") }

    before do
      sign_in(user)
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
    end

    it "navigates to the preapps task path" do
      within :sidebar do
        click_link "Check fee"
      end

      expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-validate/check-application-details/check-fee")
    end

    it "displays fee calculation for pre-applications" do
      within :sidebar do
        click_link "Check fee"
      end

      expect(page).to have_content("Fee calculation")
      expect(page).to have_content("Householder")
      expect(page).to have_content("£100")
    end

    it "hides save button when application is determined" do
      planning_application.update!(status: "determined", determined_at: Time.current)

      within :sidebar do
        click_link "Check fee"
      end

      expect(page).not_to have_button("Save and mark as complete")
    end

    context "when fee has been marked as valid" do
      before do
        task.complete!
        planning_application.update!(valid_fee: true)
      end

      it "shows the fee calculation section" do
        within :sidebar do
          click_link "Check fee"
        end

        expect(page).to have_content("Fee calculation")
        expect(page).to have_content("Householder")
        expect(page).to have_content("£100")
      end
    end
  end
end
