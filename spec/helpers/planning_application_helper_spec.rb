# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationHelper, type: :helper do
  describe "#days_color" do
    it "returns the correct colour for less than 6" do
      expect(days_color(3)).to eq("red")
    end

    it "returns the correct colour for 6..10" do
      expect(days_color(7)).to eq("yellow")
    end

    it "returns the correct colour for 11 and over" do
      expect(days_color(14)).to eq("green")
    end
  end

  describe "#map_link" do
    it "returns the correct link for a valid address" do
      expect(map_link("11 Abbey Gardens, London, SE16 3RQ")).to eq("https://google.co.uk/maps/place/11+Abbey+Gardens%2C+London%2C+SE16+3RQ")
    end
  end

  describe "#display_decision_status" do
    context "refused" do
      let(:planning_application) do
        create :planning_application, :determined, decision: "refused",
                                                   public_comment: "not valid"
      end

      it "returns correct values when application is refused" do
        expect(display_status(planning_application)[:decision]).to eql("Refused")
        expect(display_status(planning_application)[:color]).to eql("red")
      end
    end

    context "granted" do
      let(:planning_application) { create :planning_application, :determined, decision: "granted" }

      it "returns correct values when application is granted" do
        expect(display_status(planning_application)[:decision]).to eql("Granted")
        expect(display_status(planning_application)[:color]).to eql("green")
      end
    end
  end

  describe "#display_status" do
    let(:planning_application) { create :planning_application }
    let(:awaiting_planning_application) { create :planning_application, :awaiting_determination, decision: "granted" }

    it "returns correct values when application is withdrawn" do
      planning_application.withdraw!
      expect(display_status(planning_application)[:decision]).to eql("withdrawn")
      expect(display_status(planning_application)[:color]).to eql("grey")
    end

    it "returns correct values when application is returned" do
      planning_application.return!
      expect(display_status(planning_application)[:decision]).to eql("returned")
      expect(display_status(planning_application)[:color]).to eql("grey")
    end

    it "returns correct values when application is in assessment" do
      planning_application.start!
      expect(display_status(planning_application)[:decision]).to eql("In assessment")
      expect(display_status(planning_application)[:color]).to eql("turquoise")
    end

    it "returns correct values when application is awaiting determination" do
      expect(display_status(awaiting_planning_application)[:decision]).to eql("Awaiting determination")
      expect(display_status(awaiting_planning_application)[:color]).to eql("purple")
    end
  end
end
