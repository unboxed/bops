# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review committee decision" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:reviewer) do
    create(:user,
      :reviewer,
      local_authority: default_local_authority)
  end
  let!(:assessor) do
    create(:user,
      :assessor,
      local_authority: default_local_authority)
  end
  let!(:planning_application) do
    create(:planning_application, :awaiting_determination, :with_recommendation, local_authority: default_local_authority, user: assessor, in_assessment_at: Time.zone.local(2024, 11, 20, 12, 30))
  end

  before do
    create(:decision, :ldc_granted)
    create(:decision, :ldc_refused)

    allow(Current).to receive(:user).and_return(reviewer)

    sign_in reviewer

    planning_application.committee_decision.update(recommend: true, reasons: ["The first reason"])
    travel_to(Time.zone.local(2024, 11, 21, 12, 30))
    visit "/planning_applications/#{planning_application.reference}/review/tasks"
  end

  it "shows validation errors" do
    click_button "Recommendation to committee"
    within("#recommendation_to_committee_footer") do
      click_button("Save and mark as complete")
    end
    expect(page).to have_selector("[role=alert] li", text: "Select an option")
    within("#recommendation_to_committee_section") do
      expect(find("button")[:"aria-expanded"]).to eq("true")
    end

    within("#recommendation_to_committee_footer") do
      choose "Return with comments"
      click_button("Save and mark as complete")
    end

    expect(page).to have_selector("[role=alert] li", text: "Explain to the case officer why")
    within("#recommendation_to_committee_section") do
      expect(find("button")[:"aria-expanded"]).to eq("true")
    end
    within("#recommendation_to_committee_footer") do
      expect(page).to have_selector("p.govuk-error-message", text: "Explain to the case officer why")
    end
  end

  it "reviewer can agree with committee decision" do
    click_button "Recommendation to committee"
    within("#recommendation_to_committee_section") do
      expect(find(".govuk-tag")).to have_content("Not started")

      within("#recommendation_to_committee_block") do
        expect(page).to have_selector("h2", text: "Assessor recommendation")
        expect(page).to have_content("The case officer has marked this application as requiring decision by Committee for the following reasons:")
        expect(page).to have_selector("h3", text: "Reasons selected")
        expect(page).to have_selector("li", text: "The first reason")
        expect(page).to have_selector("h3", text: "Submitted recommendation")
        expect(page).to have_selector("p", text: "by #{assessor.name}, 20 November 2024 12:30")
      end

      within("#recommendation_to_committee_footer") do
        expect(page).to have_selector("legend", text: "Do you agree with the recommendation?")
        choose "Agree"
        click_button "Save and mark as complete"
      end
    end

    expect(page).to have_content "Review of committee decision recommendation updated successfully"

    within("#recommendation_to_committee_section") do
      expect(find(".govuk-tag")).to have_content("Completed")
    end
  end

  it "reviewer can disagree with decision" do
    click_button "Recommendation to committee"
    within("#recommendation_to_committee_section") do
      within("#recommendation_to_committee_footer") do
        expect(page).to have_selector("legend", text: "Do you agree with the recommendation?")
        choose "Return with comments"
        fill_in "Add a comment", with: "No committee"
        click_button "Save and mark as complete"
      end
    end

    expect(page).to have_content "Review of committee decision recommendation updated successfully"

    within("#recommendation_to_committee_section") do
      expect(find(".govuk-tag")).to have_content("Awaiting changes")
    end

    click_link "Sign off recommendation"

    expect(page).to have_content "You have suggested changes to be made by the officer."
    choose "No (return the case for assessment)"
    fill_in "Explain to the officer why the case is being returned", with: "No committee"
    click_button "Save and mark as complete"

    click_link "Application"
    click_link "Check and assess"

    expect(page).to have_list_item_for(
      "Make draft recommendation",
      with: "To be reviewed"
    )

    click_link "Make draft recommendation"

    within(".comment-component") do
      expect(page).to have_content("Reviewer comment")
      expect(page).to have_content("Sent on 21 November 2024 12:30 by #{reviewer.name}")
      expect(page).to have_content("No committee")
    end
    within_fieldset("Does this planning application need to be decided by committee?") do
      choose "No"
    end

    click_button "Update assessment"
    click_link "Review and submit recommendation"
    click_button "Submit recommendation"
    click_link "Review and sign-off"

    within("#recommendation_to_committee_section") do
      expect(find(".govuk-tag")).to have_content("Updated")

      expect(page).to have_content "The case officer has marked this application as not requiring decision by Committee."
      within("#recommendation_to_committee_footer") do
        choose "Agree"
        click_button "Save and mark as complete"
      end
    end

    expect(page).to have_content "Review of committee decision recommendation updated successfully"

    within("#recommendation_to_committee_section") do
      expect(find(".govuk-tag")).to have_content("Completed")
    end
  end
end
