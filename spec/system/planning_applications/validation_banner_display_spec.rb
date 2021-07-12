RSpec.describe "Validation banners", type: :system do
  context "Validation request banners are displayed correctly when open request is overdue" do
    let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

    let!(:planning_application) { create :planning_application, local_authority: @default_local_authority }

    let!(:description_change_validation_request) do
      create :description_change_validation_request, planning_application: planning_application, state: "open"
    end

    before do
      sign_in assessor
    end

    after do
      travel_back
    end

    it "shows the correct count for 1 overdue request validation" do
      travel 2.months
      visit planning_application_path(planning_application)
      expect(page).to have_content("1 validation request now overdue")
    end

    it "shows the correct count for 2 overdue request validations" do
      create(:replacement_document_validation_request,
             planning_application: planning_application,
             state: "open")

      travel 2.months
      visit planning_application_path(planning_application)
      expect(page).to have_content("2 validation requests now overdue")
    end
  end

  context "Validation warning banner is not displayed when request is closed" do
    let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

    let!(:planning_application) { create :planning_application, local_authority: @default_local_authority }

    let!(:description_change_validation_request) do
      create :description_change_validation_request, planning_application: planning_application, state: "closed"
    end

    let!(:replacement_document_validation_request) do
      create :replacement_document_validation_request, planning_application: planning_application, state: "closed"
    end

    before do
      travel 2.months
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    after do
      travel_back
    end

    it "does not display the overdue validation request banner" do
      expect(page).not_to have_content("now overdue.")
    end

    it "displays the resolved validation request banner" do
      expect(page).to have_content("2 new responses to a validation request.")
    end
  end
end
