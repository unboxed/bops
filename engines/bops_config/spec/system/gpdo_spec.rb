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

    within(".govuk-breadcrumbs__list") do
      expect(page).to have_link("GPDO")
      expect(page).to have_content("Schedules")
    end

    within(".govuk-table") do
      within "thead > tr:first-child" do
        expect(page).to have_selector("th:nth-child(1)", text: "Schedule")
        expect(page).to have_selector("th:nth-child(2)", text: "Description")
        expect(page).to have_selector("th:nth-child(3)", text: "Action")
      end

      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Schedule 2")
          expect(page).to have_selector("td:nth-child(2)", text: "Permitted development rights")
          within "td:nth-child(3)" do
            expect(page).to have_link(
              "Edit",
              href: "/gpdo/schedule/#{schedule.number}/edit"
            )
          end
        end
      end
    end

    click_link "Create new schedule"
    within(".govuk-breadcrumbs__list") do
      expect(page).to have_link("GPDO")
      expect(page).to have_link("Schedules")
      expect(page).to have_content("Create new schedule")
    end
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
    fill_in "Description", with: "Procedures for Article 4 directions"
    click_button "Save"

    expect(page).to have_content("GPDO schedule successfully created")

    within(".govuk-table") do
      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Schedule 2")
        end
        within "tr:nth-child(2)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Schedule 3")
          expect(page).to have_selector("td:nth-child(2)", text: "Procedures for Article 4 directions")
        end
      end
    end
  end

  it "allows editing the schedule" do
    visit "/gpdo/schedule/#{schedule.number}/edit"
    within(".govuk-breadcrumbs__list") do
      expect(page).to have_link("GPDO")
      expect(page).to have_link("Schedules")
      expect(page).to have_content("Edit schedule")
    end

    expect(page).to have_selector("h1", text: "Edit schedule")
    expect(page).to have_link("Back", href: "/gpdo/schedule")
    # Schedule number is readonly
    expect(page).to have_selector("#policy-schedule-number-field[readonly]")

    fill_in "Description", with: "Permitted Development Rights"
    click_button "Save"

    expect(page).to have_content("GPDO schedule successfully updated")

    within(".govuk-table") do
      within "tbody" do
        within "tr:nth-child(1)" do
          expect(page).to have_selector("td:nth-child(1)", text: "Schedule 2")
          expect(page).to have_selector("td:nth-child(2)", text: "Permitted Development Rights")
        end
      end
    end
  end

  context "when deleting the schedule" do
    let(:schedule3) { create(:policy_schedule, number: 3, name: "Procedures for Article 4 directions") }
    let!(:policy_part) { create(:policy_part, policy_schedule: schedule3) }

    it "allows deleting the schedule when no policy part is associated", :capybara do
      visit "/gpdo/schedule/2/edit"
      accept_confirm(text: "Are you sure?") do
        click_link("Remove")
      end

      expect(page).to have_content("GPDO schedule successfully removed")
      expect(page).not_to have_content("Schedule 2")
    end

    it "does not allow deleting the schedule when a policy part is associated" do
      visit "/gpdo/schedule/3/edit"
      expect(page).not_to have_link("Remove")
    end
  end

  context "when managing policy parts" do
    let!(:part) { create(:policy_part, number: 1, name: "Development within the curtilage of a dwellinghouse", policy_schedule: schedule) }

    it "allows viewing and creating the policy parts" do
      click_link "GPDO"
      click_link "Schedule 2"

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_link("GPDO")
        expect(page).to have_link("Schedule 2")
        expect(page).to have_content("Parts")
      end

      expect(page).to have_selector("h1", text: "Schedule 2 - Permitted development rights")

      within(".govuk-table") do
        within "thead > tr:first-child" do
          expect(page).to have_selector("th:nth-child(1)", text: "Part")
          expect(page).to have_selector("th:nth-child(2)", text: "Description")
          expect(page).to have_selector("th:nth-child(3)", text: "Action")
        end

        within "tbody" do
          within "tr:nth-child(1)" do
            expect(page).to have_selector("td:nth-child(1)", text: "1")
            expect(page).to have_selector("td:nth-child(2)", text: "Development within the curtilage of a dwellinghouse")
            within "td:nth-child(3)" do
              expect(page).to have_link(
                "Edit",
                href: "/gpdo/schedule/#{schedule.number}/part/#{part.number}/edit"
              )
            end
          end
        end
      end

      click_link "Create new part"
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Enter a number for the part")
      expect(page).to have_selector("[role=alert] li", text: "Enter a description for the part")
      fill_in "Part", with: "0"
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "The part number must be greater than or equal to 1")
      fill_in "Part", with: "21"
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "The part number must be less than or equal to 20")
      fill_in "Part", with: "NaN"
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "The part number must be a number")
      fill_in "Part", with: "1"
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Number has already been taken")

      fill_in "Part", with: "2"
      fill_in "Description", with: "Minor operations"
      click_button "Save"

      expect(page).to have_content("GPDO part successfully created")

      within(".govuk-table") do
        within "tbody" do
          within "tr:nth-child(1)" do
            expect(page).to have_selector("td:nth-child(1)", text: "1")
            expect(page).to have_selector("td:nth-child(2)", text: "Development within the curtilage of a dwellinghouse")
          end
          within "tr:nth-child(2)" do
            expect(page).to have_selector("td:nth-child(1)", text: "2")
            expect(page).to have_selector("td:nth-child(2)", text: "Minor operations")
          end
        end
      end
    end

    it "allows editing the part" do
      visit "/gpdo/schedule/2/part/#{part.number}/edit"
      within(".govuk-breadcrumbs__list") do
        expect(page).to have_link("GPDO")
        expect(page).to have_link("Schedule 2")
        expect(page).to have_link("Parts")
        expect(page).to have_content("Edit part")
      end

      expect(page).to have_selector("h1", text: "Edit part")
      expect(page).to have_link("Back", href: "/gpdo/schedule/2/part")

      fill_in "Description", with: "Changes of use"
      click_button "Save"

      expect(page).to have_content("GPDO part successfully updated")

      within(".govuk-table") do
        within "tbody" do
          within "tr:nth-child(1)" do
            expect(page).to have_selector("td:nth-child(1)", text: "1")
            expect(page).to have_selector("td:nth-child(2)", text: "Changes of use")
          end
        end
      end
    end

    context "when deleting the part" do
      let(:part2) { create(:policy_part, number: 2, name: "Minor operations", policy_schedule: schedule) }
      let!(:policy_class) { create(:new_policy_class, policy_part: part2) }

      it "allows deleting the legislation when no policy part is associated", :capybara do
        visit "/gpdo/schedule/2/part/1/edit"
        accept_confirm(text: "Are you sure?") do
          click_link("Remove")
        end

        expect(page).to have_content("GPDO part successfully removed")
        expect(page).not_to have_content("Development within the curtilage of a dwellinghouse")
      end

      it "does not allow deleting the part when a policy class is associated" do
        visit "/gpdo/schedule/2/part/2/edit"
        expect(page).not_to have_link("Remove")
      end
    end
  end
end
