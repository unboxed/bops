# frozen_string_literal: true

require "rails_helper"

RSpec.describe NeighbourResponseCreationService, type: :service do
  describe "#call" do
    let!(:planning_application) { create(:planning_application) }
    let!(:consultation) { create(:consultation, planning_application:) }

    let!(:params) do
      ActionController::Parameters.new(
        {
          "response" => "I like it",
          "address" => "123 Made up Street, E1 6LT",
          "name" => "Sophie Blog",
          "summary_tag" => "supportive"
        }
      )
    end

    let(:create_neighbour_response) do
      described_class.new(
        planning_application:,
        params:
      ).call
    end

    context "when successful" do
      it "creates a new neighbour response" do
        expect do
          create_neighbour_response
        end.to change(NeighbourResponse, :count).by(1)

        response = NeighbourResponse.last

        expect(response).to have_attributes(
          response: "I like it",
          name: "Sophie Blog",
          summary_tag: "supportive"
        )

        expect(response.neighbour).to have_attributes(
          address: "123 Made up Street, E1 6LT"
        )
      end
    end

    context "when unsuccessful" do
      let!(:params) do
        ActionController::Parameters.new(
          {
            "response" => "",
            "address" => "",
            "name" => "",
            "summary_tag" => ""
          }
        )
      end

      it "raises an error" do
        expect { create_neighbour_response }.to raise_error(described_class::CreateError)
      end
    end
  end
end
