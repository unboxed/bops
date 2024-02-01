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
    visit "/planning_applications/#{planning_application.id}/validation/tasks"
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
        within("#application-details-tasks") do
          expect(page).to have_content("Check application details")

          within("#draw_red_line_boundary") do
            expect(page).to have_link(
              "Draw red line boundary",
              href: planning_application_validation_sitemap_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#check-red-line-boundary") do
            expect(page).to have_content("Check red line boundary")
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#constraints-validation-tasks") do
            expect(page).to have_link(
              "Check constraints",
              href: planning_application_validation_constraints_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#check-description") do
            expect(page).to have_link(
              "Check description",
              href: planning_application_validation_description_changes_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#development-type-for-reporting-task") do
            expect(page).to have_link(
              "Select development type for reporting",
              href: edit_planning_application_validation_reporting_type_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          expect(page).not_to have_css("#check-legislative-requirements")
        end

        within("#check-tag-documents-tasks") do
          expect(page).to have_content("Check and tag supplied documents")

          within("#check-supplied-document-#{document.name.parameterize}") do
            expect(page).to have_link(
              "Check supplied document - #{document.name}",
              href: edit_planning_application_document_path(planning_application, document, validate: "yes")
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end
        end

        within("#application-requirements-tasks") do
          expect(page).to have_content("Confirm application requirements")

          within("#fee-validation-task") do
            expect(page).to have_link(
              "Check fee",
              href: planning_application_validation_fee_items_path(planning_application)
            )
          end

          within("#cil-liability-validation-tasks") do
            expect(page).to have_link(
              "CIL liability",
              href: edit_planning_application_validation_cil_liability_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#environment-impact-assessment-task") do
            expect(page).to have_link(
              "Check Environment Impact Assessment",
              href: new_planning_application_validation_environment_impact_assessment_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#ownership-certificate-validation-task") do
            expect(page).to have_link(
              "Check ownership certificate",
              href: edit_planning_application_validation_ownership_certificate_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end
        end

        within("#confirm-documents-tasks") do
          expect(page).to have_content("Confirm documents")

          within("#check-provided-documents") do
            expect(page).to have_link(
              "Check provided documents",
              href: validation_documents_planning_application_path(planning_application)
            )
          end

          within("#upload-redacted-documents") do
            expect(page).to have_link(
              "Upload redacted documents",
              href: planning_application_validation_documents_redactions_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end
        end

        within("#other-change-validation-tasks") do
          expect(page).to have_content("Other validation issues")
          expect(page).to have_link(
            "Add another validation request",
            href: new_planning_application_validation_validation_request_path(planning_application, type: "other_change")
          )
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

    context "when planning application type is prior approval 1A" do
      let!(:planning_application) do
        create(:planning_application, :prior_approval, :not_started, local_authority: default_local_authority)
      end

      before do
        planning_application.application_type.update(part: 1, section: "A")

        sign_in assessor
        visit "/planning_applications/#{planning_application.id}/validation/tasks"
      end

      it "shows the check legislation task" do
        within("#check-legislative-requirements") do
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
        within("#application-details-tasks") do
          expect(page).to have_content("Check application details")

          within("#draw_red_line_boundary") do
            expect(page).to have_link(
              "Draw red line boundary",
              href: planning_application_validation_sitemap_path(planning_application)
            )
            within(".govuk-tag--green") do
              expect(page).to have_content("Checked")
            end
          end

          within("#check-red-line-boundary") do
            expect(page).to have_content("Check red line boundary")
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#constraints-validation-tasks") do
            expect(page).to have_link(
              "Check constraints",
              href: planning_application_validation_constraints_path(planning_application)
            )
            within(".govuk-tag--green") do
              expect(page).to have_content("Checked")
            end
          end

          within("#check-description") do
            expect(page).to have_content("Planning application has already been validated")
            expect(page).not_to have_link("Check description")
          end

          within("#development-type-for-reporting-task") do
            expect(page).to have_link(
              "Select development type for reporting",
              href: edit_planning_application_validation_reporting_type_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          expect(page).not_to have_css("#check-legislative-requirements")
        end

        within("#check-tag-documents-tasks") do
          expect(page).to have_content("Check and tag supplied documents")

          within("#check-supplied-document") do
            expect(page).to have_content("Planning application has already been validated")
            expect(page).not_to have_link("Check supplied document")
          end
        end

        within("#application-requirements-tasks") do
          expect(page).to have_content("Confirm application requirements")

          within("#fee-validation-task") do
            expect(page).to have_content("Planning application has already been validated")
            expect(page).not_to have_link("Check fee")
          end

          within("#cil-liability-validation-tasks") do
            expect(page).to have_link(
              "CIL liability",
              href: edit_planning_application_validation_cil_liability_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#environment-impact-assessment-task") do
            expect(page).to have_link(
              "Check Environment Impact Assessment",
              href: new_planning_application_validation_environment_impact_assessment_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end

          within("#ownership-certificate-validation-task") do
            expect(page).to have_link(
              "Check ownership certificate",
              href: edit_planning_application_validation_ownership_certificate_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end
        end

        within("#confirm-documents-tasks") do
          expect(page).to have_content("Confirm documents")

          within("#check-provided-documents") do
            expect(page).to have_content("Planning application has already been validated")
            expect(page).not_to have_link("Check supplied document - #{document.name}")
          end

          within("#upload-redacted-documents") do
            expect(page).to have_link(
              "Upload redacted documents",
              href: planning_application_validation_documents_redactions_path(planning_application)
            )
            within(".govuk-tag--grey") do
              expect(page).to have_content("Not started")
            end
          end
        end

        within("#other-change-validation-tasks") do
          expect(page).to have_content("Other validation issues")
          expect(page).not_to have_link("Add an other validation request")
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

    context "when planning application type is prior approval 1A" do
      let!(:planning_application) do
        create(:planning_application, :prior_approval, :in_assessment, local_authority: default_local_authority)
      end

      before do
        planning_application.application_type.update(part: 1, section: "A")

        sign_in assessor
        visit "/planning_applications/#{planning_application.id}/validation/tasks"
      end

      it "shows the check legislation task" do
        within("#check-legislative-requirements") do
          expect(page).to have_content("Planning application has already been validated")
        end
      end
    end
  end
end
