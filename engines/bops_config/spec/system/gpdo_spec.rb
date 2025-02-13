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
    expect(page).to have_selector("h1", text: "GPDO")

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
      end

      expect(page).to have_selector("span.govuk-caption-m", text: "Schedule 2")
      expect(page).to have_selector("h1", text: "Permitted development rights")

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
      let!(:policy_class) { create(:policy_class, policy_part: part2) }

      it "allows deleting the part when no policy classes are associated", :capybara do
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

  context "when managing policy classes" do
    let!(:part) { create(:policy_part, number: 1, name: "Development within the curtilage of a dwellinghouse", policy_schedule: schedule) }
    let!(:policy_classA) { create(:policy_class, section: "A", name: "enlargement, improvement or other alteration of a dwellinghouse", policy_part: part) }
    let!(:policy_classAA) { create(:policy_class, section: "AA", name: "enlargement of a dwellinghouse by construction of additional storeys", policy_part: part) }
    let!(:policy_classB) { create(:policy_class, section: "B", name: "additions etc to the roof of a dwellinghouse", policy_part: part) }

    it "allows viewing and creating the policy classes" do
      click_link "GPDO"
      click_link "Schedule 2"
      click_link "Development within the curtilage of a dwellinghouse"

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_link("GPDO")
        expect(page).to have_link("Schedule 2")
      end

      expect(page).to have_selector("h1", text: "Development within the curtilage of a dwellinghouse")
      expect(page).to have_selector("span.govuk-caption-m", text: "Part 1")

      within(".govuk-table") do
        within "thead > tr:first-child" do
          expect(page).to have_selector("th:nth-child(1)", text: "Class")
          expect(page).to have_selector("th:nth-child(2)", text: "Description")
          expect(page).to have_selector("th:nth-child(3)", text: "Action")
        end

        within "tbody" do
          within "tr:nth-child(1)" do
            expect(page).to have_selector("td:nth-child(1)", text: "A")
            expect(page).to have_selector("td:nth-child(2)", text: "enlargement, improvement or other alteration of a dwellinghouse")
            within "td:nth-child(3)" do
              expect(page).to have_link(
                "Edit",
                href: "/gpdo/schedule/#{schedule.number}/part/#{part.number}/class/#{policy_classA.section}/edit"
              )
            end
          end
          within "tr:nth-child(2)" do
            expect(page).to have_selector("td:nth-child(1)", text: "AA")
            expect(page).to have_selector("td:nth-child(2)", text: "enlargement of a dwellinghouse by construction of additional storeys")
            within "td:nth-child(3)" do
              expect(page).to have_link(
                "Edit",
                href: "/gpdo/schedule/#{schedule.number}/part/#{part.number}/class/#{policy_classAA.section}/edit"
              )
            end
          end
          within "tr:nth-child(3)" do
            expect(page).to have_selector("td:nth-child(1)", text: "B")
            expect(page).to have_selector("td:nth-child(2)", text: "additions etc to the roof of a dwellinghouse")
            within "td:nth-child(3)" do
              expect(page).to have_link(
                "Edit",
                href: "/gpdo/schedule/#{schedule.number}/part/#{part.number}/class/#{policy_classB.section}/edit"
              )
            end
          end
        end
      end

      click_link "Create new class"
      expect(page).to have_link("Back", href: "/gpdo/schedule/2/part/1/class")
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Enter a section for the class")
      expect(page).to have_selector("[role=alert] li", text: "Enter a description for the class")
      fill_in "Link (optional)", with: "invalid link"
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Url is invalid")
      fill_in "Class", with: "C"
      fill_in "Description", with: "other alterations to the roof of a dwellinghouse"
      fill_in "Link (optional)", with: "https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-c-other-alterations-to-the-roof-of-a-dwellinghouse"
      click_button "Save"

      expect(page).to have_content("GPDO class successfully created")

      within(".govuk-table") do
        within "tbody" do
          within "tr:nth-child(4)" do
            expect(page).to have_selector("td:nth-child(1)", text: "C")
            expect(page).to have_selector("td:nth-child(2)", text: "other alterations to the roof of a dwellinghouse")
          end
        end
      end
    end

    it "allows editing the policy class" do
      visit "/gpdo/schedule/2/part/1/class/B/edit"
      within(".govuk-breadcrumbs__list") do
        expect(page).to have_link("GPDO")
        expect(page).to have_link("Schedule 2")
        expect(page).to have_link("Part 1")
      end

      expect(page).to have_selector("h1", text: "Edit class")
      expect(page).to have_link("Back", href: "/gpdo/schedule/2/part/1/class")

      expect(page).to have_selector("#policy-class-section-field[readonly]")
      fill_in "Description", with: "other alterations to the roof of a dwellinghouse"
      fill_in "Link (optional)", with: "https://www.legislation.gov.uk/uksi/2015/596/schedule/2/part/1/crossheading/class-c-other-alterations-to-the-roof-of-a-dwellinghouse"
      click_button "Save"

      expect(page).to have_content("GPDO class successfully updated")

      within(".govuk-table") do
        within "tbody" do
          within "tr:nth-child(3)" do
            expect(page).to have_selector("td:nth-child(1)", text: "B")
            expect(page).to have_selector("td:nth-child(2)", text: "other alterations to the roof of a dwellinghouse")
          end
        end
      end
    end

    context "when deleting the policy class" do
      let!(:policy_section) { create(:policy_section, policy_class: policy_classAA) }

      it "allows deleting the policy class when no policy sections are associated", :capybara do
        visit "/gpdo/schedule/2/part/1/class/A/edit"
        accept_confirm(text: "Are you sure?") do
          click_link("Remove")
        end

        expect(page).to have_content("GPDO class successfully removed")
        expect(page).not_to have_content("enlargement, improvement or other alteration of a dwellinghouse")
      end

      it "does not allow deleting the policy class when a policy section is associated" do
        visit "/gpdo/schedule/2/part/1/class/AA/edit"
        expect(page).not_to have_link("Remove")
      end
    end
  end

  context "when managing policy sections" do
    let!(:part) { create(:policy_part, number: 1, name: "Development within the curtilage of a dwellinghouse", policy_schedule: schedule) }
    let!(:policy_classAA) { create(:policy_class, section: "AA", name: "enlargement of a dwellinghouse by construction of additional storeys", policy_part: part) }
    let!(:policy_section) { create(:policy_section, section: "1b(ii)", title: "Development not permitted", description: "if the dwellinghouse is located on a site of special scientific interest", policy_class: policy_classAA) }

    it "allows viewing and creating the policy sections" do
      click_link "GPDO"
      click_link "Schedule 2"
      click_link "Development within the curtilage of a dwellinghouse"
      click_link "enlargement of a dwellinghouse by construction of additional storeys"

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_link("GPDO")
        expect(page).to have_link("Schedule 2")
        expect(page).to have_link("Part 1")
      end

      expect(page).to have_selector("h1", text: "enlargement of a dwellinghouse by construction of additional storeys")
      expect(page).to have_selector("span.govuk-caption-m", text: "Class AA")

      within("#policy-sections") do
        within(".govuk-summary-card#development-not-permitted") do
          expect(page).to have_content("AA.1b(ii)")
          expect(page).to have_content("Development not permitted")
          expect(page).to have_content("if the dwellinghouse is located on a site of special scientific interest")
        end
      end

      click_link "Create new policy section"
      expect(page).to have_link("Back", href: "/gpdo/schedule/2/part/1/class/AA/section")
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Enter a section for the policy section")
      expect(page).to have_selector("[role=alert] li", text: "Enter a description for the policy section")
      fill_in "Section", with: "1b(i)"
      select "Interpretation", from: "Title"
      fill_in "Description", with: "if the dwellinghouse is located on article 2(3) land"
      click_button "Save"

      expect(page).to have_content("Policy section successfully created")

      within("#policy-sections") do
        within(".govuk-summary-card#interpretation") do
          expect(page).to have_content("AA.1b(i)")
          expect(page).to have_content("Interpretation")
          expect(page).to have_content("if the dwellinghouse is located on article 2(3) land")
        end
      end
    end

    it "allows editing the policy section" do
      visit "/gpdo/schedule/2/part/1/class/AA/section/1b(ii)/edit"
      within(".govuk-breadcrumbs__list") do
        expect(page).to have_link("GPDO")
        expect(page).to have_link("Schedule 2")
        expect(page).to have_link("Part 1")
        expect(page).to have_link("Class AA")
      end

      expect(page).to have_selector("h1", text: "Edit policy section")
      expect(page).to have_link("Back", href: "/gpdo/schedule/2/part/1/class/AA/section")

      fill_in "Description", with: "if the dwellinghouse is located on a site of special environmental interest"
      select "Conditions", from: "Title"
      click_button "Save"

      expect(page).to have_content("Policy section successfully updated")

      within("#policy-sections") do
        within(".govuk-summary-card#conditions") do
          expect(page).to have_content("if the dwellinghouse is located on a site of special environmental interest")
        end
      end
    end

    context "when deleting the policy section" do
      let!(:policy_section1a) { create(:policy_section, section: "1a", policy_class: policy_classAA) }
      let!(:planning_application_policy_section) { create(:planning_application_policy_section, policy_section:) }

      it "allows deleting the policy section when no planning application policy sections are associated", :capybara do
        visit "/gpdo/schedule/2/part/1/class/AA/section/1a/edit"
        accept_confirm(text: "Are you sure?") do
          click_link("Remove")
        end

        expect(page).to have_content("Policy section successfully removed")
        expect(page).not_to have_content("1a")
      end

      it "does not allow deleting the policy section when a planning application policy section is associated" do
        visit "/gpdo/schedule/2/part/1/class/AA/section/1b(ii)/edit"
        expect(page).not_to have_link("Remove")
      end
    end
  end
end
