# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validation tasks", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create :user, :assessor, local_authority: default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: default_local_authority
  end
  let!(:document) do
    create(:document, :with_file, planning_application: planning_application)
  end

  before do
    sign_in assessor
    visit planning_application_validation_tasks_path(planning_application)
  end

  context "when application is not started or invalidated" do
    let!(:planning_application) do
      create :planning_application, :invalidated, local_authority: default_local_authority
    end

    it "displays the basic planning application information" do
      within("#planning-application-details") do
        expect(page).to have_content(planning_application.reference)
        expect(page).to have_content(planning_application.full_address)
        expect(page).to have_content(planning_application.description)
        expect(page).to have_content("Invalid")
      end
    end

    it "displays the validation tasks item count" do
      within("#validation-tasks-item-counter") do
        expect(page).to have_content("Check the application")

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
            href: planning_application_fee_items_path(planning_application, validate_fee: "yes")
          )
        end

        within("#other-change-validation-tasks") do
          expect(page).to have_content("Other validation issues")
          expect(page).to have_link(
            "Add an other validation request",
            href: new_planning_application_other_change_validation_request_path(planning_application)
          )
        end

        within("#document-validation-tasks") do
          expect(page).to have_content("Check supplied documents")
          expect(page).to have_link(
            "Check document - #{document.name}",
            href: edit_planning_application_document_path(planning_application, document, validate: "yes")
          )
          within(".govuk-tag--grey") do
            expect(page).to have_content("Not checked yet")
          end
        end

        within("#constraints-validation-tasks") do
          expect(page).to have_content("Constraints")
          expect(page).to have_link(
            "Check constraints",
            href: planning_application_constraints_path(planning_application)
          )
          within(".govuk-tag--grey") do
            expect(page).to have_content("Not checked yet")
          end
        end

        within("#red-line-boundary-tasks") do
          expect(page).to have_content("Red line boundary")

          within("#draw_red_line_boundary") do
            expect(page).to have_link(
              "Draw red line boundary",
              href: planning_application_sitemap_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not checked yet")
            end
          end

          within("#validate_red_line_boundary") do
            expect(page).to have_content("Check red line boundary")
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not checked yet")
            end
          end
        end

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
  end

  context "when application has been validated" do
    let!(:planning_application) do
      create :planning_application, :in_assessment, :with_boundary_geojson, local_authority: default_local_authority,
                                                                            constraints_checked: true
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
            href: planning_application_constraints_path(planning_application)
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
              href: planning_application_sitemap_path(planning_application)
            )
            within(".govuk-tag--green") do
              expect(page).to have_content("Checked")
            end
          end

          within("#validate_red_line_boundary") do
            expect(page).to have_link(
              "Check red line boundary",
              href: planning_application_sitemap_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not checked yet")
            end
          end
        end

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
  end
end
