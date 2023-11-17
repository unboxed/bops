# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validation tasks" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority)
  end
  let!(:document) do
    create(:document, :with_file, planning_application:)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}/validation_tasks"
  end

  context "when application is not started or invalidated" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, local_authority: default_local_authority)
    end

    it "displays the basic planning application information" do
      within("#planning-application-details") do
        expect(page).to have_content("Check the application")
        expect(page).to have_content(planning_application.reference)
        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content(planning_application.description)
        expect(page).to have_content("Invalid")
      end
    end

    it "displays the validation tasks item count" do
      within("#validation-tasks-item-counter") do
        within("#invalid-items-count") do
          expect(page).to have_content("Invalid items 0")
        end
        within("#updated-items-count") do
          expect(page).to have_content("Updated items 0")
        end
      end
    end

    it "displays the validation tasks list" do
      within(".app-task-list") do
        within("#fee-validation-task") do
          expect(page).to have_content("Fee")
          expect(page).to have_link(
            "Check fee",
            href: planning_application_validation_fee_items_path(planning_application, validate_fee: "yes")
          )
        end

        within("#other-change-validation-tasks") do
          expect(page).to have_content("Other validation issues")
          expect(page).to have_link(
            "Add an other validation request",
            href: new_planning_application_validation_other_change_validation_request_path(planning_application)
          )
        end

        within("#document-validation-tasks") do
          expect(page).to have_content("Check supplied documents")
          expect(page).to have_link(
            "Check document - #{document.name}",
            href: edit_planning_application_document_path(planning_application, document, validate: "yes")
          )
          within(".govuk-tag--grey") do
            expect(page).to have_content("Not started")
          end
        end

        within("#constraints-validation-tasks") do
          expect(page).to have_content("Constraints")
          expect(page).to have_link(
            "Check constraints",
            href: planning_application_validation_constraints_path(planning_application)
          )
          within(".govuk-tag--grey") do
            expect(page).to have_content("Not started")
          end
        end

        within("#red-line-boundary-tasks") do
          expect(page).to have_content("Red line boundary")

          within("#draw_red_line_boundary") do
            expect(page).to have_link(
              "Draw red line boundary",
              href: planning_application_validation_sitemap_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          expect(page).to have_list_item_for(
            "Check red line boundary",
            with: "Not started"
          )
        end

        expect(page).not_to have_css("#check-legislation-task")

        within("#review-tasks") do
          expect(page).to have_content("Review")
          expect(page).to have_link(
            "Send validation decision",
            href: validation_decision_planning_application_path(planning_application)
          )
        end
      end

      expect(page).to have_link("Back", href: planning_application_path(planning_application))
    end

    context "when planning application type is prior approval 1A" do
      let!(:planning_application) do
        create(:planning_application, :prior_approval, :not_started, local_authority: default_local_authority)
      end

      before do
        planning_application.application_type.update(part: 1, section: "A")

        sign_in assessor
        visit "/planning_applications/#{planning_application.id}/validation_tasks"
      end

      it "shows the check legislation task" do
        within("#check-legislation-task") do
          expect(page).to have_content("Legislation")
          expect(page).to have_content("Check legislative requirements")
          expect(page).to have_content("Not started")
        end
      end
    end
  end

  context "when application has been validated" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, :with_boundary_geojson, local_authority: default_local_authority,
        constraints_checked: true)
    end

    it "displays the validation tasks list but no actions to create new requests can be taken" do
      within(".app-task-list") do
        within("#fee-validation-task") do
          expect(page).to have_content("Fee")
          expect(page).to have_content("Planning application has already been validated")
          expect(page).not_to have_link("Check fee")
        end

        within("#other-change-validation-tasks") do
          expect(page).to have_content("Other validation issues")
          expect(page).not_to have_link("Add an other validation request")
        end

        within("#document-validation-tasks") do
          expect(page).to have_content("Check supplied documents")
          expect(page).to have_content("Planning application has already been validated")
          expect(page).not_to have_link("Check document - #{document.name}")
        end

        within("#constraints-validation-tasks") do
          expect(page).to have_content("Constraints")
          expect(page).to have_link(
            "Check constraints",
            href: planning_application_validation_constraints_path(planning_application)
          )
          within(".govuk-tag--green") do
            expect(page).to have_content("Checked")
          end
        end

        within("#red-line-boundary-tasks") do
          expect(page).to have_content("Red line boundary")

          within("#draw_red_line_boundary") do
            expect(page).to have_link(
              "Draw red line boundary",
              href: planning_application_validation_sitemap_path(planning_application)
            )
            within(".govuk-tag--green") do
              expect(page).to have_content("Checked")
            end
          end

          expect(page).to have_list_item_for(
            "Check red line boundary",
            with: "Not started"
          )
        end

        expect(page).not_to have_css("#check-legislation-task")

        within("#review-tasks") do
          expect(page).to have_content("Review")
          expect(page).to have_link(
            "Send validation decision",
            href: validation_decision_planning_application_path(planning_application)
          )
        end
      end

      expect(page).to have_link("Back", href: planning_application_path(planning_application))
    end

    context "when planning application type is prior approval 1A" do
      let!(:planning_application) do
        create(:planning_application, :prior_approval, :in_assessment, local_authority: default_local_authority)
      end

      before do
        planning_application.application_type.update(part: 1, section: "A")

        sign_in assessor
        visit "/planning_applications/#{planning_application.id}/validation_tasks"
      end

      it "shows the check legislation task" do
        within("#check-legislation-task") do
          expect(page).to have_content("Legislation")
          expect(page).to have_content("Planning application has already been validated")
        end
      end
    end
  end
end
