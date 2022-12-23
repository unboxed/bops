# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskListItems::FeeComponent, type: :component do
  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  context "when planning application has valid fee" do
    let(:planning_application) do
      create(:planning_application, valid_fee: true)
    end

    before { render_inline(component) }

    it "renders 'Valid' status" do
      expect(page).to have_content("Valid")
    end

    it "renders link to fee items path" do
      expect(page).to have_link(
        "Check fee",
        href: "/planning_applications/#{planning_application.id}/fee_items?validate_fee=yes"
      )
    end
  end

  context "when check is not started" do
    let(:planning_application) { create(:planning_application) }

    before { render_inline(component) }

    it "renders 'Not started' status" do
      expect(page).to have_content("Not started")
    end

    it "renders link to fee items path" do
      expect(page).to have_link(
        "Check fee",
        href: "/planning_applications/#{planning_application.id}/fee_items?validate_fee=yes"
      )
    end
  end

  context "when there is an open request" do
    let(:planning_application) { create(:planning_application, :not_started) }

    let!(:other_change_validation_request) do
      create(
        :other_change_validation_request,
        fee_item: true,
        planning_application: planning_application
      )
    end

    before { render_inline(component) }

    it "renders 'Invalid' status" do
      expect(page).to have_content("Invalid")
    end

    it "renders link to fee items path" do
      expect(page).to have_link(
        "Check fee",
        href: "/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}"
      )
    end
  end

  context "when there is a closed request" do
    let(:planning_application) { create(:planning_application, :not_started) }

    let!(:other_change_validation_request) do
      create(
        :other_change_validation_request,
        :closed,
        fee_item: true,
        planning_application: planning_application
      )
    end

    before { render_inline(component) }

    it "renders 'Invalid' status" do
      expect(page).to have_content("Updated")
    end

    it "renders link to fee items path" do
      expect(page).to have_link(
        "Check fee",
        href: "/planning_applications/#{planning_application.id}/other_change_validation_requests/#{other_change_validation_request.id}"
      )
    end
  end
end
