# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validating the application" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor
    visit "/"
  end

  describe "viewing the prepopulated valid from date field" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, validated_at: nil, local_authority: default_local_authority)
    end

    context "when there is a closed validation request" do
      let!(:validation_request) do
        create(:red_line_boundary_change_validation_request, planning_application:)
      end

      context "when the request was closed during work hours" do
        before do
          # 04/01/2023 12:00
          travel_to(DateTime.new(2023, 1, 4, 12)) do
            validation_request.close!
            visit "/planning_applications/#{planning_application.id}/confirm_validation"
          end
        end

        it "prepopulates with the closed at date" do
          expect(page).to have_field("Day", with: "4")
          expect(page).to have_field("Month", with: "1")
          expect(page).to have_field("Year", with: "2023")
        end
      end

      context "when the request was closed outside work hours" do
        before do
          # 04/01/2023 18:00
          travel_to(DateTime.new(2023, 1, 4, 18)) do
            validation_request.close!
            visit "/planning_applications/#{planning_application.id}/confirm_validation"
          end
        end

        it "prepopulates with the business day after the closed at date" do
          expect(page).to have_field("Day", with: "5")
          expect(page).to have_field("Month", with: "1")
          expect(page).to have_field("Year", with: "2023")
        end
      end

      context "when the request was closed on a non business day" do
        before do
          # 01/01/2023 12:00
          travel_to(DateTime.new(2023, 1, 1, 12)) do
            validation_request.close!
            visit "/planning_applications/#{planning_application.id}/confirm_validation"
          end
        end

        it "prepopulates with the business day after the closed at date" do
          expect(page).to have_field("Day", with: "3")
          expect(page).to have_field("Month", with: "1")
          expect(page).to have_field("Year", with: "2023")
        end
      end
    end

    context "when there is no closed validation request" do
      before { visit "/planning_applications/#{planning_application.id}/confirm_validation" }

      context "when the planning application was created during work hours" do
        let(:planning_application) do
          travel_to(DateTime.new(2023, 1, 5, 12)) do
            create(:planning_application, :invalidated, validated_at: nil, local_authority: default_local_authority)
          end
        end

        it "prepopulates with the created at date" do
          expect(page).to have_field("Day", with: "5")
          expect(page).to have_field("Month", with: "1")
          expect(page).to have_field("Year", with: "2023")
        end
      end

      context "when the planning application was created outside work hours" do
        let(:planning_application) do
          travel_to(DateTime.new(2023, 1, 5, 18)) do
            create(:planning_application, :invalidated, validated_at: nil, local_authority: default_local_authority)
          end
        end

        it "prepopulates with the business day after the created at date" do
          expect(page).to have_field("Day", with: "6")
          expect(page).to have_field("Month", with: "1")
          expect(page).to have_field("Year", with: "2023")
        end
      end

      context "when the planning application was created on a non business day" do
        let(:planning_application) do
          travel_to(DateTime.new(2023, 1, 8)) do
            create(:planning_application, :invalidated, validated_at: nil, local_authority: default_local_authority)
          end
        end

        it "prepopulates with the business day after the created at date" do
          expect(page).to have_field("Day", with: "9")
          expect(page).to have_field("Month", with: "1")
          expect(page).to have_field("Year", with: "2023")
        end
      end
    end
  end
end
