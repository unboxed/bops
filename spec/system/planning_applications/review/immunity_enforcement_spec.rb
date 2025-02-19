# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing immunity enforcement" do
  let(:default_local_authority) { create(:local_authority, :default) }

  let(:reviewer) do
    create(
      :user,
      :reviewer,
      local_authority: default_local_authority,
      name: "Charlize The Reviever"
    )
  end

  let(:assessor) { create(:user, local_authority: default_local_authority) }

  let(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      :with_recommendation,
      :with_immunity,
      local_authority: default_local_authority,
      decision: :granted
    )
  end

  context "when there's not an immunity enforcement" do
    before do
      sign_in reviewer
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    it "I cannot view the link of Review assessment of immunity page" do
      expect(page).not_to have_link("Review assessment of immunity")
    end
  end

  context "when there's an immunity enforcement" do
    before do
      create(:review, :enforcement, owner: planning_application.immunity_detail, assessor:)

      sign_in reviewer
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    context "when planning application is awaiting determination" do
      it "I can save and mark as complete when adding my review to accept the review evidence of immunity response" do
        within("#review-immunity-enforcements") do
          expect(page).to have_content("Review assessment of immunity")
          expect(page).to have_content("Not started")
        end

        click_button "Review assessment of immunity"

        within("#review-immunity-enforcements") do
          expect(page).not_to have_content("Immunity from enforcement summary")
          expect(page).to have_content("Assessor decision: Yes")
          expect(page).to have_content("Reason: it looks immune to me")
          expect(page).to have_content("Summary: they have enough bills to show it's immune")
        end

        within("#review-immunity-enforcements-form") do
          choose "Agree"

          click_button "Save and mark as complete"
        end

        within("#review-immunity-enforcements") do
          expect(page).to have_content("Review assessment of immunity")
          expect(page).to have_content("Completed")
        end
      end

      it "when I return it with comments, they can see my comments" do
        click_button "Review assessment of immunity"

        within("#review-immunity-enforcements-form") do
          choose "Return with comments"

          fill_in "Add a comment", with: "Please re-assess"

          click_button "Save and mark as complete"
        end

        within("#review-immunity-enforcements") do
          expect(page).to have_content("Review assessment of immunity")
          expect(page).to have_content("Awaiting changes")
        end

        click_link "Application"
        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Immunity/permitted development rights",
          with: "To be reviewed"
        )

        click_link "Immunity/permitted development rights"
        find("span", text: "See previous review immunity detail responses").click

        expect(page).to have_content("Please re-assess")
      end
    end
  end
end
