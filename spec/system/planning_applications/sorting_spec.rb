# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning application sorting", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :assessor, local_authority:) }

  let!(:planning_application_1) {
    travel_to(10.days.ago) do
      create(:planning_application, :ldc_proposed, :in_assessment, local_authority:, user:)
    end
  }
  let!(:planning_application_2) {
    travel_to(5.days.ago) do
      create(:planning_application, :ldc_proposed, :in_assessment, local_authority:, user:)
    end
  }
  let!(:planning_application_3) {
    travel_to(7.days.ago) do
      create(:planning_application, :ldc_proposed, :in_assessment, local_authority:, user:)
    end
  }
  let!(:planning_application_4) {
    travel_to(1.days.ago) do
      create(:planning_application, :ldc_proposed, :awaiting_determination, local_authority:, user:)
    end
  }

  before do
    sign_in user
  end

  it "I can sort by expiry date" do
    visit "/#all"
    within selected_govuk_tab do
      expect(page).to have_css("button.arrow.unsorted")

      click_link("Expiry date")

      expect(page).to have_css("button.arrow.ascending")

      within(".govuk-table.planning-applications-table") do
        within(".govuk-table__body") do
          rows = page.all(".govuk-table__row")

          within(rows[0]) do
            expect(page).to have_content(planning_application_1.reference)
          end

          within(rows[1]) do
            expect(page).to have_content(planning_application_3.reference)
          end

          within(rows[2]) do
            expect(page).to have_content(planning_application_2.reference)
          end

          within(rows[3]) do
            expect(page).to have_content(planning_application_4.reference)
          end
        end
      end

      click_link("Expiry date")
      expect(page).to have_css("button.arrow.descending")
      within(".govuk-table.planning-applications-table") do
        within(".govuk-table__body") do
          rows = page.all(".govuk-table__row")

          within(rows[0]) do
            expect(page).to have_content(planning_application_4.reference)
          end

          within(rows[1]) do
            expect(page).to have_content(planning_application_2.reference)
          end

          within(rows[2]) do
            expect(page).to have_content(planning_application_3.reference)
          end

          within(rows[3]) do
            expect(page).to have_content(planning_application_1.reference)
          end
        end
      end

      uncheck "Awaiting determination"
      click_button "Apply filters"
      click_link("Expiry date")
      click_link("Expiry date")
      within(".govuk-table.planning-applications-table") do
        within(".govuk-table__body") do
          rows = page.all(".govuk-table__row")

          within(rows[0]) do
            expect(page).to have_content(planning_application_2.reference)
          end

          within(rows[1]) do
            expect(page).to have_content(planning_application_3.reference)
          end

          within(rows[2]) do
            expect(page).to have_content(planning_application_1.reference)
          end
        end
      end
    end
  end
end
