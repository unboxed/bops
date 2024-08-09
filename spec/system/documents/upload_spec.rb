# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document uploads" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create(:planning_application,
      local_authority: default_local_authority,
      decision: "granted")
  end

  let!(:document) { create(:document, planning_application:) }
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  context "as an assessor" do
    before { sign_in assessor }

    context "when the application is under assessment" do
      it "cannot upload a document in the wrong format" do
        visit "/planning_applications/#{planning_application.reference}/documents"

        click_link("Upload document")
        attach_file("Upload a file", "spec/fixtures/images/image.gif")
        check("Floor plan - existing")

        click_button("Save")

        expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
      end

      it "cannot save without a document being attached" do
        visit "/planning_applications/#{planning_application.reference}/documents"

        click_link("Upload document")
        check("Floor plan - existing")
        click_button("Save")

        expect(page).to have_content("Please choose a file")
      end
    end
  end
end
