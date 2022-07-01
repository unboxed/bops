# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationHelper, type: :helper do
  describe "#map_link" do
    it "returns the correct link for a valid address" do
      expect(map_link("11 Abbey Gardens, London, SE16 3RQ")).to eq("https://google.co.uk/maps/place/11+Abbey+Gardens%2C+London%2C+SE16+3RQ")
    end
  end

  describe "#mapit_link" do
    it "returns the correct link for a postcode" do
      expect(mapit_link("se16 3Rq")).to eq("https://mapit.mysociety.org/postcode/SE163RQ.html")
      expect(mapit_link("s e16 3 rQ")).to eq("https://mapit.mysociety.org/postcode/SE163RQ.html")
    end
  end

  describe "#display_number" do
    it "returns the right number for an element in an array" do
      expect(display_number([25, 84, "proposal", 165, true], 165)).to eq(4)
    end
  end

  describe "#red_line_boundary_post_validation_action_link" do
    let(:planning_application) { create(:planning_application, :in_assessment) }

    context "when red line boundary change post validation request is open" do
      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, :open, planning_application: planning_application)
      end

      it "returns url to view requested red line boundary change" do
        expect(red_line_boundary_post_validation_action_link(planning_application)).to eq(
          link_to("View requested red line boundary change", planning_application_red_line_boundary_change_validation_request_path(planning_application, red_line_boundary_change_validation_request), class: "govuk-link")
        )
      end
    end

    context "when red line boundary change post validation request is closed" do
      let!(:red_line_boundary_change_validation_request) do
        create(:red_line_boundary_change_validation_request, :closed, planning_application: planning_application)
      end

      it "returns url to view requested red line boundary change" do
        expect(red_line_boundary_post_validation_action_link(planning_application)).to eq(
          link_to("View applicants response to requested red line boundary change", planning_application_red_line_boundary_change_validation_request_path(planning_application, red_line_boundary_change_validation_request), class: "govuk-link")
        )
      end
    end

    context "when red line boundary change post validation request is cancelled" do
      before do
        create(:red_line_boundary_change_validation_request, :cancelled, planning_application: planning_application)
      end

      it "returns url to view requested red line boundary change" do
        expect(red_line_boundary_post_validation_action_link(planning_application)).to eq(
          link_to("Request approval for a change to red line boundary", new_planning_application_red_line_boundary_change_validation_request_path(planning_application), class: "govuk-link")
        )
      end
    end

    context "when red line boundary change post validation request does not exist" do
      it "returns url to view requested red line boundary change" do
        expect(red_line_boundary_post_validation_action_link(planning_application)).to eq(
          link_to("Request approval for a change to red line boundary", new_planning_application_red_line_boundary_change_validation_request_path(planning_application), class: "govuk-link")
        )
      end
    end
  end
end
