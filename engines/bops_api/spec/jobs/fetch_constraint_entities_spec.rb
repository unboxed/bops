# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::PlanningApplicationDependencyJob, type: :job do
  let(:arguments) do
    [planning_application_constraint, entities]
  end

  context "when www.planning.data.gov.uk returns an invalid response" do
    let(:planning_application_constraint) { create(:planning_application_constraint) }
    let(:entities) { [source: "https://www.planning.data.gov.uk/entity/999"] }

    it "sets the status as failed" do
      stub_request(:get, "https://www.planning.data.gov.uk/entity/999.json")
        .to_return(
          status: 200,
          headers: {"Content-Type" => "text/html"},
          body: "<p>Invalid Response</p>"
        )

      expect {
        described_class.new.send(:fetch_constraint_entities, *arguments)
      }.to change {
        planning_application_constraint.data
      }.from(nil).to([]).and change {
        planning_application_constraint.status
      }.from("pending").to("failed")
    end
  end

  context "when the source url isn't www.planning.data.gov.uk" do
    let(:planning_application_constraint) { create(:planning_application_constraint) }
    let(:entities) { [source: "https://www.ordnancesurvey.co.uk/products/os-mastermap-highways-network-roads"] }

    it "sets the data to an empty array and sets the status to failed" do
      expect {
        described_class.new.send(:fetch_constraint_entities, *arguments)
      }.to change {
        planning_application_constraint.data
      }.from(nil).to([]).and change {
        planning_application_constraint.status
      }.from("pending").to("failed")
    end
  end

  context "when the source url returns a 404" do
    let!(:planning_application_constraint) { create(:planning_application_constraint) }
    let(:entities) { [source: "https://www.planning.data.gov.uk/entity/999"] }

    it "sets the data to an empty array and sets the status to 'not_found'" do
      stub_request(:get, "https://www.planning.data.gov.uk/entity/999.json")
        .to_return(
          status: 404,
          headers: {"Content-Type" => "text/html"},
          body: "<p>Not Found</p>"
        )

      expect {
        described_class.new.send(:fetch_constraint_entities, *arguments)
      }.to change {
        planning_application_constraint.data
      }.from(nil).to([]).and change {
        planning_application_constraint.status
      }.from("pending").to("not_found")
    end
  end

  context "when the source url returns a 410 Gone response" do
    let!(:planning_application_constraint) { create(:planning_application_constraint) }
    let(:entities) { [source: "https://www.planning.data.gov.uk/entity/999"] }

    it "sets the data to an empty array and sets the status to 'removed'" do
      stub_request(:get, "https://www.planning.data.gov.uk/entity/999.json")
        .to_return(
          status: 410,
          headers: {"Content-Type" => "text/html"},
          body: "<p>Gone</p>"
        )

      expect {
        described_class.new.send(:fetch_constraint_entities, *arguments)
      }.to change {
        planning_application_constraint.data
      }.from(nil).to([]).and change {
        planning_application_constraint.status
      }.from("pending").to("removed")
    end
  end

  context "when the source is a string" do
    let(:planning_application_constraint) { create(:planning_application_constraint) }
    let(:entities) { [source: "https://www.planning.data.gov.uk/entity/999"] }

    it "sets the data to the returned JSON" do
      stub_request(:get, "https://www.planning.data.gov.uk/entity/999.json")
        .to_return(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: %({"name":"Somewhere Road Tree Protection Zone"})
        )

      expect {
        described_class.new.send(:fetch_constraint_entities, *arguments)
      }.to change {
        planning_application_constraint.data
      }.from(nil).to([{"name" => "Somewhere Road Tree Protection Zone"}])
    end
  end

  context "when the source is a hash with a url" do
    let(:planning_application_constraint) { create(:planning_application_constraint) }
    let(:entities) { [source: {text: "Planning Data", url: "https://www.planning.data.gov.uk/entity/999"}] }

    it "sets the data to the returned JSON" do
      stub_request(:get, "https://www.planning.data.gov.uk/entity/999.json")
        .to_return(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: %({"name":"Somewhere Road Tree Protection Zone"})
        )

      expect {
        described_class.new.send(:fetch_constraint_entities, *arguments)
      }.to change {
        planning_application_constraint.data
      }.from(nil).to([{"name" => "Somewhere Road Tree Protection Zone"}]).and change {
        planning_application_constraint.status
      }.from("pending").to("success")
    end
  end

  context "when the source is a hash without a url" do
    let(:planning_application_constraint) { create(:planning_application_constraint) }
    let(:entities) { [source: {text: "Ordnance Survey MasterMap Highways"}] }

    it "sets the data to an empty array" do
      expect {
        described_class.new.send(:fetch_constraint_entities, *arguments)
      }.to change {
        planning_application_constraint.data
      }.from(nil).to([])
    end
  end
end
