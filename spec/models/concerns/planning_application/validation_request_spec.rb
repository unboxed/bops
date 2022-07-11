# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplication::ValidationRequest do
  describe "#open_post_validation_requests" do
    let(:planning_application) { create(:planning_application, :in_assessment) }

    before do
      create(:red_line_boundary_change_validation_request, :cancelled, :post_validation, planning_application: planning_application)
      create(:red_line_boundary_change_validation_request, :closed, :post_validation, planning_application: planning_application)
    end

    context "when there are no open post validation requests" do
      it "returns an empty array" do
        expect(planning_application.open_post_validation_requests).to eq([])
        expect(planning_application).not_to be_open_post_validation_requests
      end
    end

    context "when there are open post validation requests" do
      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, :open, :post_validation, planning_application: planning_application)
      end

      it "returns the array" do
        expect(planning_application.open_post_validation_requests).to match_array([red_line_boundary_change_validation_request])
        expect(planning_application).to be_open_post_validation_requests
      end
    end
  end

  describe "#validation_requests" do
    let(:planning_application) { create(:planning_application, :invalidated) }

    let!(:red_line_boundary_change_validation_request) do
      create(
        :red_line_boundary_change_validation_request,
        planning_application: planning_application,
        created_at: 1.day.ago
      )
    end

    let!(:post_validation_red_line_boundary_change_validation_request) do
      create(:red_line_boundary_change_validation_request, :post_validation, planning_application: planning_application)
    end

    let!(:other_change_validation_request) do
      create(
        :other_change_validation_request,
        planning_application: planning_application,
        created_at: 2.days.ago
      )
    end

    let!(:replacement_document_validation_request) do
      create(
        :replacement_document_validation_request,
        planning_application: planning_application,
        created_at: 3.days.ago
      )
    end

    let!(:additional_document_validation_request) do
      create(
        :additional_document_validation_request,
        planning_application: planning_application,
        created_at: 4.days.ago
      )
    end

    let!(:description_change_validation_request) do
      create(
        :description_change_validation_request,
        planning_application: planning_application,
        created_at: 5.days.ago
      )
    end

    context "when no argument is supplied" do
      it "returns validation requests where post_validation is false" do
        expect(planning_application.validation_requests).to eq(
          [red_line_boundary_change_validation_request, other_change_validation_request, replacement_document_validation_request, additional_document_validation_request]
        )
      end
    end

    context "when argument supplied with post_validation: true" do
      it "returns validation requests where post_validation is true" do
        expect(planning_application.validation_requests(post_validation: true)).to match_array(
          [post_validation_red_line_boundary_change_validation_request]
        )
      end
    end

    context "when include_description_change_validation_requests is true" do
      it "returns all validation requests" do
        expect(
          planning_application.validation_requests(
            include_description_change_validation_requests: true
          )
        ).to eq(
          [
            red_line_boundary_change_validation_request,
            other_change_validation_request,
            replacement_document_validation_request,
            additional_document_validation_request,
            description_change_validation_request
          ]
        )
      end
    end
  end
end
