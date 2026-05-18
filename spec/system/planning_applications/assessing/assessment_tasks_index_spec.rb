# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assessment tasks", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor

    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  context "when the planning application is in_assessment, I can assess the planning application" do
    let(:planning_application) do
      create(
        :planning_application,
        :in_assessment,
        local_authority: default_local_authority
      )
    end

    context "when sidebar is enabled" do
      it "redirects to the first available task" do
        expect(page).to have_current_path(%r{^/planning_applications/#{planning_application.reference}/check-and-assess})
      end
    end

    context "when planning application is a pre application" do
      let(:planning_application) do
        create(:planning_application, :in_assessment, :pre_application, :with_additional_services, uprn: "100081043511", local_authority: default_local_authority)
      end

      before do
        paapi_data("100081043511").each do |record|
          create(
            :site_history,
            planning_application:,
            reference: record["reference"],
            date: record["decision_issued_at"],
            description: record["description"],
            decision: record["decision"],
            comment: "A comment that is relevant to the proposal"
          )
        end
      end

      it "redirects to the first task" do
        expect(page).to have_selector("h1")
        expect(page.current_path).to match("/preapps/#{planning_application.reference}/check-and-assess/")
      end

      it "displays the preview report button link" do
        within(".bops-sidebar") do
          expect(page).to have_link("Preview report", href: bops_reports.planning_application_path(planning_application, view_as: "applicant"))
        end
      end
    end
  end

  context "when the planning application is invalidated, I cannot access the assessment tasks", :pending do
    let(:planning_application) do
      create(
        :planning_application,
        :invalidated,
        local_authority: default_local_authority
      )
    end

    it "displays a forbidden message" do
      expect(page).to have_content("The planning application must be validated before assessment can begin")
    end
  end
end
