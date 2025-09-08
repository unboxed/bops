# frozen_string_literal: true

require "rails_helper"

RSpec.describe "assessment check development type", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, :planx, local_authority: local_authority) }

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      :with_constraints,
      local_authority:,
      api_user:
    )
  end

  context "when planning application is not planning permission" do
    context "when I'm signed in as an assessor" do
      let(:assessor) do
        create(
          :user,
          :assessor,
          local_authority:,
          name: "Alice Smith"
        )
      end

      before do
        sign_in(assessor)
        visit "/planning_applications/#{planning_application.reference}"
      end

      context "when assessing development type" do
        it "shows cannot started yet on add new assessment area" do
          click_link("Check and assess")

          within("#add-new-assessment-area") do
            expect(page).to have_content("Add new assessment area")
            expect(page).to have_content("Cannot start yet")
          end
        end
        it "shows an error if the assessor doesn't choose the proposal is development" do
          click_link("Check and assess")

          within("#check-if-the-proposal-is-development") do
            expect(page).to have_link(
              "Check if the proposal is development",
              href: "/planning_applications/#{planning_application.reference}/assessment/development_type/edit"
            )
            expect(page).to have_content("Not started")
          end

          within("#assess-against-legislation-tasks") do
            click_link("Check if the proposal is development")
          end

          click_button("Save and mark as complete")
          expect(page).to have_content("Section 55 development is not included in the list")
        end

        context "lets the assessor choose the proposal is development" do
          it "choose yes that proposal is development" do
            click_link("Check and assess")

            within("#assess-against-legislation-tasks") do
              click_link("Check if the proposal is development")
            end

            choose("Yes")
            click_button("Save and mark as complete")

            expect(page).to have_content("Section 55 development was successfully updated")

            within("#check-if-the-proposal-is-development") do
              expect(page).to have_link(
                "Check if the proposal is development",
                href: "/planning_applications/#{planning_application.reference}/assessment/development_type/edit"
              )
              expect(page).to have_content("Completed")
            end

            within("#add-new-assessment-area") do
              expect(page).to have_link("Add new assessment area")
            end
          end
          it "choose no that proposal is development" do
            click_link("Check and assess")

            within("#assess-against-legislation-tasks") do
              click_link("Check if the proposal is development")
            end

            choose("No")
            click_button("Save and mark as complete")

            expect(page).to have_content("Section 55 development was successfully updated")

            within("#check-if-the-proposal-is-development") do
              expect(page).to have_link(
                "Check if the proposal is development",
                href: "/planning_applications/#{planning_application.reference}/assessment/development_type/edit"
              )
              expect(page).to have_content("Completed")
            end

            within("#add-new-assessment-area") do
              expect(page).to have_content("Add new assessment area")
              expect(page).to have_content("Not required")
            end
          end
        end
      end
    end
  end

  context "when planning application is planning permission" do
    let(:planning_application) do
      create(
        :planning_application,
        :planning_permission,
        :in_assessment,
        :with_constraints,
        local_authority:,
        api_user:
      )
    end

    before do
      assessor =
        create(
          :user,
          :assessor,
          local_authority:,
          name: "Alice Smith"
        )

      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}"
    end

    it "doesn't show development type" do
      click_link "Check and assess"

      expect(page).to have_content("Assess against policies and guidance")
      expect(page).not_to have_content("Check if the proposal is development")
    end
  end
end
