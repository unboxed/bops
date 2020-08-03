# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document uploads", type: :system do
  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate
  end

  let!(:drawing) { create :drawing, :with_plan, planning_application: planning_application }

  context "for an assessor" do
    before { sign_in users(:assessor) }

    context "when the application is under assessment" do
      scenario "can upload, tag and confirm documents" do
        visit planning_application_drawings_path(planning_application)

        click_link("Upload documents")

        attach_file("Upload a file", "spec/fixtures/images/existing-floorplan.pdf")

        check("floor plan - existing")
        check("section - proposed")

        click_button("Continue")

        expect(page).to have_css("img[src*=\"existing-floorplan.pdf\"]")

        expect(page).to have_css(".govuk-tag", text: "floor plan - existing")
        expect(page).to have_css(".govuk-tag", text: "section - proposed")

        choose("No, I need to go back")

        click_button("Continue")

        expect(page).to have_checked_field("floor plan - existing")
        expect(page).to have_checked_field("section - proposed")

        attach_file("Upload a file", "spec/fixtures/images/proposed-section.pdf")

        uncheck("floor plan - existing")

        # section - proposed remains checked
        check("section - existing")

        click_button("Continue")

        expect(page).to have_css("img[src*=\"proposed-section.pdf\"]")

        expect(page).to have_css(".govuk-tag", text: "section - proposed")
        expect(page).to have_css(".govuk-tag", text: "section - existing")

        choose("Yes, upload this file")

        click_button("Continue")

        expect(page).to have_content("proposed-section.pdf has been uploaded.")

        expect(page).to have_css(".current-drawings .thumbnail", count: 2)

        within(".current-drawings .thumbnail:last-child") do
          # The newly added document is last in the list
          expect(page).to have_css("img[src*=\"proposed-section.pdf\"]")

          expect(page).to have_css(".govuk-tag", text: "section - proposed")
          expect(page).to have_css(".govuk-tag", text: "section - existing")
        end

        find(".govuk-breadcrumbs").click_link("Application")

        click_button("Proposal documents")

        within(find(".scroll-docs")) do
          expect(all("img").count).to eq 2
          expect(all("img").last["src"]).to have_content("proposed-section.pdf")

          expect(page).to have_css(".govuk-tag", text: "section - proposed")
          expect(page).to have_css(".govuk-tag", text: "section - existing")
        end
      end

      scenario "cannot progress to confirmation without a tagged document" do
        visit planning_application_drawings_path(planning_application)

        click_link("Upload documents")

        click_button("Continue")

        expect(page).to have_content("Upload new document")

        expect(page).to have_content("Please choose a file")
        expect(page).to have_content("Please select one or more tags")
      end

      scenario "cannot upload a document in the wrong format" do
        visit planning_application_drawings_path(planning_application)

        click_link("Upload documents")

        attach_file("Upload a file", "spec/fixtures/images/bmp.bmp")

        check("floor plan - existing")

        click_button("Continue")

        choose("Yes, upload this file")

        click_button("Continue")

        expect(page).to have_content("Plan is not a supported file format")
      end
    end

    context "when the planning application has been submitted for review" do
      before { planning_application.awaiting_determination! }

      scenario "the upload \"button\" is disabled" do
        visit planning_application_drawings_path(planning_application)

        # The enabled call-to-action is a link, but to show it as disabled
        # we replace it with a button.
        expect(page).not_to have_link("Upload documents")
        expect(page).to have_button("Upload documents", disabled: true)
      end
    end
  end

  context "for a reviewer" do
    before { sign_in users(:reviewer) }

    scenario "no upload actions are visible at all" do
      visit planning_application_drawings_path(planning_application)

      # Neither the enabled call-to-action or its disabled, button
      # equivalent are visible.
      expect(page).not_to have_link("Upload documents")
      expect(page).not_to have_button("Upload documents", disabled: true)
    end
  end
end
