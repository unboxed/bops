# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::FetchConstraintEntitiesJob, type: :job do
  let(:arguments) do
    [planning_application_constraint, entities]
  end

  context "when www.planning.data.gov.uk returns an invalid response" do
    let(:planning_application_constraint) { create(:planning_application_constraint) }
    let(:entities) { [source: "https://www.planning.data.gov.uk/entity/999"] }

    it "raises an error" do
      stub_request(:get, "https://www.planning.data.gov.uk/entity/999.json")
        .to_return(
          status: 200,
          headers: {"Content-Type" => "text/html"},
          body: "<p>Invalid Response</p>"
        )

      expect {
        described_class.perform_now(*arguments)
      }.to raise_error(
        BopsApi::Errors::InvalidEntityResponseError,
        "Request for entity https://www.planning.data.gov.uk/entity/999.json returned a non-JSON response"
      )
    end
  end
end