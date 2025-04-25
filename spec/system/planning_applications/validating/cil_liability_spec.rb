# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Community Infrastructure Levy (CIL)", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let(:planning_application) do
    create(:planning_application, :not_started, local_authority: default_local_authority)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  it "is listed as incomplete by default" do
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"

    within "#cil-liability-task" do
      expect(page).to have_content "Confirm Community Infrastructure Levy (CIL)"
      expect(page).to have_content "Not started"
    end
  end

  it "can be marked as liable" do
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
    click_link "Confirm Community Infrastructure Levy (CIL)"
    choose "Yes"
    click_button "Save and mark as complete"

    expect(page).to have_content "CIL liability updated"
    within "#cil-liability-task" do
      expect(page).to have_content "Confirm Community Infrastructure Levy (CIL)"
      expect(page).to have_content "Completed"
    end
  end

  it "can be marked as not liable" do
    visit "/planning_applications/#{planning_application.reference}/validation/tasks"
    click_link "Confirm Community Infrastructure Levy (CIL)"
    choose "No"
    click_button "Save and mark as complete"

    expect(page).to have_content "CIL liability updated"
    within "#cil-liability-task" do
      expect(page).to have_content "Confirm Community Infrastructure Levy (CIL)"
      expect(page).to have_content "Completed"
    end
  end

  context "when revisiting the edit page" do
    it "is marked as true when liable" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Confirm Community Infrastructure Levy (CIL)"
      choose "Yes"
      click_button "Save and mark as complete"

      click_link "Confirm Community Infrastructure Levy (CIL)"

      expect(page).to have_checked_field("planning-application-cil-liable-true-field")
      expect(page).not_to have_checked_field("planning-application-cil-liable-field")
    end

    it "is marked as false when not liable" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Confirm Community Infrastructure Levy (CIL)"
      choose "No"
      click_button "Save and mark as complete"

      click_link "Confirm Community Infrastructure Levy (CIL)"

      expect(page).not_to have_checked_field("planning-application-cil-liable-true-field")
      expect(page).to have_checked_field("planning-application-cil-liable-field")
    end
  end

  context "when there is no liability information from planx" do
    it "explains that there is no liability information" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Confirm Community Infrastructure Levy (CIL)"

      expect(page).to have_content("No information on potential CIL liability from PlanX.")
    end

    it "does not preselect any radio button" do
      visit "/planning_applications/#{planning_application.reference}/validation/tasks"
      click_link "Confirm Community Infrastructure Levy (CIL)"

      expect(find_by_id("planning-application-cil-liable-true-field")).not_to be_selected
      expect(find_by_id("planning-application-cil-liable-field")).not_to be_selected
    end
  end

  context "when there is liability information from planx" do
    before do
      planx_planning_data = instance_double(PlanxPlanningData)
      params_v2 = {data: {CIL: {result: planx_response, proposedTotalArea: {squareMetres: planx_size}}}}
      allow(planx_planning_data).to receive(:params_v2).and_return(params_v2)
      allow_any_instance_of(PlanningApplication).to receive(:planx_planning_data).and_return(planx_planning_data)
    end

    context "when the application might be liable" do
      let(:planx_response) { "liable" }
      let(:planx_size) { 420 }

      it "shows relevant liability information" do
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"
        click_link "Confirm Community Infrastructure Levy (CIL)"

        expect(page).to have_content("420m²")
        expect(page).to have_content("This might mean that the application is liable for CIL.")
      end

      it "selects yes by default" do
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"
        click_link "Confirm Community Infrastructure Levy (CIL)"

        expect(page).to have_checked_field("planning-application-cil-liable-true-field")
        expect(page).not_to have_checked_field("planning-application-cil-liable-field")
      end
    end

    context "when the application might not be liable" do
      let(:planx_response) { "notLiable" }
      let(:planx_size) { 88.8 }

      it "shows relevant liability information" do
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"
        click_link "Confirm Community Infrastructure Levy (CIL)"

        expect(page).to have_content("88.8m²")
        expect(page).to have_content("This might mean that the application is not liable for CIL.")
      end

      context "and no size is given" do
        let(:planx_size) { nil }
        it "shows relevant liability information" do
          visit "/planning_applications/#{planning_application.reference}/validation/tasks"
          click_link "Confirm Community Infrastructure Levy (CIL)"

          expect(page).to have_content("According to PlanX the application is not liable for CIL.")
        end
      end

      it "selects no by default" do
        visit "/planning_applications/#{planning_application.reference}/validation/tasks"
        click_link "Confirm Community Infrastructure Levy (CIL)"

        expect(page).not_to have_checked_field("planning-application-cil-liable-true-field")
        expect(page).to have_checked_field("planning-application-cil-liable-field")
      end
    end
  end

  context "when CIL liability feature is disabled" do
    let!(:planning_application) do
      create(:planning_application, :not_started, :pre_application, local_authority: default_local_authority)
    end

    it "does not have a section to check CIL" do
      visit "planning_applications/#{planning_application.reference}/validation/tasks"

      expect(page).not_to have_content("Check Community Infrastructure Levy (CIL)")

      visit "planning_applications/#{planning_application.reference}/validation/cil_liability/edit"

      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/tasks")
    end
  end
end
