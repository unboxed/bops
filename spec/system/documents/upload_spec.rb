# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document uploads", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create :planning_application,
           local_authority: default_local_authority,
           decision: "granted"
  end

  let!(:document) { create :document, planning_application: planning_application }
  let(:assessor) { create :user, :assessor, local_authority: default_local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: default_local_authority }

  context "for an assessor" do
    before { sign_in assessor }

    it "lets the assessor upload a document" do
      visit planning_application_documents_path(planning_application)
      click_link("Upload document")

      attach_file(
        "Upload a file",
        "spec/fixtures/images/existing-first-floor-plan.pdf"
      )

      fill_in("Day", with: "1")
      fill_in("Month", with: "6")
      fill_in("Year", with: "2022")
      click_button("Save")

      expect(page).to have_content(
        "existing-first-floor-plan.pdf has been uploaded."
      )

      expect(page).to have_content("File name: existing-first-floor-plan.pdf")
      expect(page).to have_content("Date received: 1 June 2022")
    end

    context "when the application is under assessment" do
      it "cannot upload a document in the wrong format" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload document")
        attach_file("Upload a file", "spec/fixtures/images/bmp.bmp")
        check("Floor")

        click_button("Save")

        expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
      end

      it "cannot save without a document being attached" do
        visit planning_application_documents_path(planning_application)

        click_link("Upload document")
        check("Floor")
        click_button("Save")

        expect(page).to have_content("Please choose a file")
      end
    end

    context "when the planning application has been submitted for review" do
      let!(:planning_application) { create(:submitted_planning_application, local_authority: default_local_authority) }

      it "the upload \"button\" is disabled" do
        visit planning_application_documents_path(planning_application)

        # The enabled call-to-action is a link, but to show it as disabled
        # we replace it with a button.
        expect(page).not_to have_link("Upload document")
        expect(page).to have_button("Upload document", disabled: true)
      end
    end

    context "when a date is entered" do
      # extract into shared examples?

      before do
        visit planning_application_documents_path(planning_application)
        click_link("Upload document")
      end

      context "when value is missing" do
        it "renders error message" do
          within("#received_at") do
            fill_in("Day", with: "1")
            fill_in("Year", with: "2022")
          end

          click_button("Save")

          expect(find("#received_at-error")).to have_content("is invalid")

          within("#received_at") do
            expect(page).to have_field("Day", with: "1")
            expect(page).to have_field("Month", with: "")
            expect(page).to have_field("Year", with: "2022")
          end
        end
      end

      context "when value is not numeric" do
        it "renders error message" do
          within("#received_at") do
            fill_in("Day", with: "1")
            fill_in("Month", with: "abc")
            fill_in("Year", with: "2022")
          end

          click_button("Save")

          expect(find("#received_at-error")).to have_content("is invalid")

          within("#received_at") do
            expect(page).to have_field("Day", with: "1")
            expect(page).to have_field("Month", with: "abc")
            expect(page).to have_field("Year", with: "2022")
          end
        end
      end

      context "when value is not a date" do
        it "renders error message" do
          within("#received_at") do
            fill_in("Day", with: "1")
            fill_in("Month", with: "100")
            fill_in("Year", with: "2022")
          end

          click_button("Save")

          expect(find("#received_at-error")).to have_content("is invalid")

          within("#received_at") do
            expect(page).to have_field("Day", with: "1")
            expect(page).to have_field("Month", with: "100")
            expect(page).to have_field("Year", with: "2022")
          end
        end
      end

      context "when values are valid" do
        it "does not render error message" do
          within("#received_at") do
            fill_in("Day", with: "1")
            fill_in("Month", with: "6")
            fill_in("Year", with: "2022")
          end

          click_button("Save")

          expect(page).not_to have_selector("#received_at-error")

          within("#received_at") do
            expect(page).to have_field("Day", with: "1")
            expect(page).to have_field("Month", with: "6")
            expect(page).to have_field("Year", with: "2022")
          end
        end
      end
    end
  end
end
