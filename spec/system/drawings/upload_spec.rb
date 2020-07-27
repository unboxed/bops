# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document uploads", type: :system do
  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate
  end

  context "for an assessor" do
    before { sign_in users(:assessor) }

    context "when the application is under assessment" do
      scenario "can upload, tag and confirm documents" do
        visit planning_application_drawings_path(planning_application)

        expect(page).to have_link("Upload documents")

        # TODO: Go though upload workflow.
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
