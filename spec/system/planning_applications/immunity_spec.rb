# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validating the application" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  context "when not immune" do
    before do
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    let(:planning_application) do
      create(:planning_application, :invalidated, validated_at: nil, local_authority: default_local_authority)
    end

    it "returns false from possibly_immune?" do
      expect(planning_application.possibly_immune?).to be false
    end

    it "doesn't mention immunity in the page header" do
      expect(page).not_to have_content("may be immune from enforcement")
    end
  end

  context "when immune" do
    let(:planning_application) do
      create(:planning_application, :invalidated, validated_at: nil, local_authority: default_local_authority)
    end

    before do
      allow_any_instance_of(PlanningApplication).to receive(:possibly_immune?).and_return(true)
      sign_in assessor
      visit planning_application_path(planning_application)
    end

    it "returns true from possibly_immune?" do
      expect(planning_application.possibly_immune?).to be true
    end

    it "mentions immunity in the page header" do
      expect(page).to have_content("may be immune from enforcement")
    end
  end
end
