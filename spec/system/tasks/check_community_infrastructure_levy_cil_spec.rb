# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Confirm community infrastructure levy CIL task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :planning_permission, :not_started, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/confirm-application-requirements/confirm-community-infrastructure-levy-cil") }

  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and validate"
  end

  context "when marking the application as CIL liable" do
    it "completes the task" do
      within ".bops-sidebar" do
        click_link "Confirm Community Infrastructure Levy (CIL)"
      end

      choose "Yes"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
      expect(planning_application.reload.cil_liable).to be true
    end
  end

  context "when marking the application as not CIL liable" do
    it "completes the task" do
      within ".bops-sidebar" do
        click_link "Confirm Community Infrastructure Levy (CIL)"
      end

      choose "No"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
      expect(planning_application.reload.cil_liable).to be false
    end
  end

  context "when submitting without selecting an option" do
    it "displays a validation error" do
      within ".bops-sidebar" do
        click_link "Confirm Community Infrastructure Levy (CIL)"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Select whether the application is liable for CIL.")
      expect(task.reload).not_to be_completed
    end
  end

  context "when the application is CIL exempt" do
    before do
      create(:planx_planning_data, planning_application:, params_v2: {
        data: {
          application: {
            CIL: {
              result: "exempt.smallResidential",
              proposedTotalArea: {
                net: {
                  squareMetres: 80
                }
              }
            }
          }
        }
      })
    end

    it "displays the exemption recommendation" do
      within ".bops-sidebar" do
        click_link "Confirm Community Infrastructure Levy (CIL)"
      end

      expect(page).to have_content("exempt from CIL")
      expect(page).to have_content("80m²")
      expect(page).to have_content("(recommended based on submission data)")
    end
  end

  context "when the application is recommended as CIL liable" do
    before do
      create(:planx_planning_data, planning_application:, params_v2: {
        data: {
          application: {
            CIL: {
              result: "liable",
              proposedTotalArea: {
                net: {
                  squareMetres: 420
                }
              }
            }
          }
        }
      })
    end

    it "displays the liability recommendation" do
      within ".bops-sidebar" do
        click_link "Confirm Community Infrastructure Levy (CIL)"
      end

      expect(page).to have_content("liable for CIL")
      expect(page).to have_content("420m²")
      expect(page).to have_content("(recommended based on submission data)")
    end
  end

  context "when changing the answer" do
    before do
      planning_application.update!(cil_liable: true)
      task.update!(status: :completed)
    end

    it "allows changing from liable to not liable" do
      within ".bops-sidebar" do
        click_link "Confirm Community Infrastructure Levy (CIL)"
      end

      click_button "Edit"

      choose "No"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed
      expect(planning_application.reload.cil_liable).to be false
    end
  end
end
