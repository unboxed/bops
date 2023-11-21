# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check ownership certificate type" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}/validation/tasks"
  end

  context "when application is not started" do
    let!(:planning_application) do
      create(
        :planning_application, :not_started,
        local_authority: default_local_authority
      )
    end

    let!(:document1) { create(:document, planning_application:, tags: ["Proposed"]) }
    let!(:document2) { create(:document, planning_application:, tags: ["Planning Statement"]) }

    let!(:ownership_certificate) { create(:ownership_certificate, planning_application:) }
    let!(:land_owner1) { create(:land_owner, ownership_certificate:) }
    let!(:land_owner2) { create(:land_owner, :not_notified, ownership_certificate:) }

    context "when I agree with the type" do
      it "allows me to mark it as valid" do
        click_link "Check ownership certificate"

        click_button "Documents"

        expect(page).to have_content("Proposed")
        expect(page).not_to have_content("Planning Statement")

        expect(page).to have_content("Certificate type B")

        expect(page).to have_content(land_owner1.name)
        expect(page).to have_content(land_owner1.address_1)
        expect(page).to have_content(land_owner1.postcode)

        expect(page).to have_content(land_owner2.name)
        expect(page).to have_content(land_owner2.address_1)
        expect(page).to have_content(land_owner2.postcode)

        choose "Yes"

        click_button "Save"

        expect(page).to have_content "Ownership certificate successfully updated"

        within("#ownership-certificate-validation-task") do
          expect(page).to have_content("Valid")
        end
      end
    end
  end
end
