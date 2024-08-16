# frozen_string_literal: true

require "bops_config_helper"

RSpec.describe "GPDO", type: :system do
  let(:user) { create(:user, :global_administrator, name: "Clark Kent", local_authority: nil) }
  let!(:schedule) { create(:policy_schedule, number: 2, name: "Permitted development rights") }

  before do
    sign_in(user)
    visit "/"
  end

  it "allows viewing and creating the policy schedules" do
    click_link "GPDO"
    expect(page).to have_selector("h1", text: "Schedules")

    within(".govuk-table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Name")
        expect(page).to have_selector("th:nth-child(2)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Schedule 2 - Permitted development rights")
          within "td:nth-child(2)" do
            expect(page).to have_link(
              "Edit",
              href: "/gpdo/schedules/#{schedule.number}/edit"
            )
          end
        end
      end
    end

    click_link "Create new schedule"
    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "Enter a number for the schedule")
    fill_in "Number", with: "0"
    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "The schedule number must be greater than or equal to 1")
    fill_in "Number", with: "5"
    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "The schedule number must be less than or equal to 4")
    fill_in "Number", with: "NaN"
    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "The schedule number must be a number")
    fill_in "Number", with: "2"
    click_button "Save"
    expect(page).to have_selector("[role=alert] li", text: "Number has already been taken")

    fill_in "Number", with: "3"
    fill_in "Name", with: "Procedures for Article 4 directions"
    click_button "Save"

    expect(page).to have_content("GPDO schedule successfully created")

    within(".govuk-table") do
      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Schedule 2 - Permitted development rights")
        end
        within "tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Schedule 3 - Procedures for Article 4 directions")
        end
      end
    end
  end

  it "allows editing the schedule" do
    visit "/gpdo/schedules/#{schedule.number}/edit"
    expect(page).to have_selector("h1", text: "Edit schedule")
    expect(page).to have_link("Back", href: "/gpdo/schedules")
    # Schedule number is readonly
    expect(page).to have_selector("#policy-schedule-number-field[readonly]")

    fill_in "Name", with: "Permitted Development Rights"
    click_button "Save"

    expect(page).to have_content("GPDO schedule successfully updated")

    within(".govuk-table") do
      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Schedule 2 - Permitted Development Rights")
        end
      end
    end
  end

  context "when deleting the legislation" do
    let(:schedule3) { create(:policy_schedule, number: 3, name: "Procedures for Article 4 directions") }
    let!(:policy_part) { create(:policy_part, policy_schedule: schedule3) }

    it "allows deleting the legislation when no policy part is associated", :capybara do
      visit "/gpdo/schedules/2/edit"
      accept_confirm(text: "Are you sure?") do
        click_link("Remove")
      end

      expect(page).to have_content("GPDO schedule successfully removed")
      expect(page).not_to have_content("Schedule 2 - Permitted development rights")
    end

    it "does not allow deleting the legislation when a policy part is associated" do
      visit "/gpdo/schedules/3/edit"
      expect(page).not_to have_link("Remove")
    end
  end
end
