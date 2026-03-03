# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Site visit task", type: :system do
  %i[planning_permission lawfulness_certificate].each do |application_type|
    context "for a #{application_type.to_s.humanize.downcase} case" do
      let(:planning_application) do
        create(:planning_application, application_type, :in_assessment, local_authority:)
      end

      it_behaves_like "site visit task", :pre_application, "check-and-assess/assessment-summaries/site-visit"
    end
  end

  context "for a prior approval case" do
    let(:local_authority) { create(:local_authority, :default) }
    let(:user) { create(:user, local_authority:) }

    let(:planning_application) do
      create(:planning_application, :prior_approval, :in_assessment, local_authority:)
    end

    before do
      sign_in(user)
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
    end

    it "doesn't have a site visit task" do
      expect(page).to have_selector("h1", text: "Assess the application")

      within :sidebar do
        expect(page).not_to have_link("Site visit")
      end
    end
  end
end
