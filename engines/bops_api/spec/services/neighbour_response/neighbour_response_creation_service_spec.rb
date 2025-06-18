# frozen_string_literal: true

require "rails_helper"

RSpec.describe NeighbourResponseCreationService do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :householder) }
  let(:planning_application) { create(:planning_application, :published, local_authority:, application_type:) }
  let(:consultation) { planning_application.consultation }

  describe "#call" do
    context "with valid parameters and new neighbour" do
      let(:params) do
        ActionController::Parameters.new(
          address: "45 Test Avenue, London, W1 1AA",
          name: "Alice",
          email: "alice@example.com",
          response: "I support this proposal.",
          summary_tag: "supportive"
        )
      end

      it "creates a neighbour response and a new neighbour" do
        service = described_class.new(planning_application:, params:)

        expect {
          response = service.call
          expect(response).to be_persisted
          expect(response.response).to eq("I support this proposal.")
          expect(response.neighbour.address).to eq("45 Test Avenue, London, W1 1AA")
        }.to change { consultation.neighbour_responses.count }.by(1)
          .and change { consultation.neighbours.count }.by(1)
      end
    end

    context "with an existing neighbour" do
      let!(:neighbour) { create(:neighbour, consultation:, address: "45 Test Avenue, London, W1 1AA") }

      let(:params) do
        ActionController::Parameters.new(
          address: "45 Test Avenue, London, W1 1AA",
          name: "Bob",
          email: "bob@example.com",
          response: "Looks fine to me.",
          summary_tag: "supportive"
        )
      end

      it "reuses the existing neighbour" do
        service = described_class.new(planning_application:, params:)

        response = service.call

        expect(response).to be_persisted
        expect(response.neighbour).to eq(neighbour)
        expect(consultation.neighbours.count).to eq(1)
      end
    end

    # context "when response is invalid" do
    #   let(:params) do
    #     ActionController::Parameters.new(
    #       address: "Missing Response Avenue"
    #       # response is missing
    #     )
    #   end

    #   it "raises a CreateError" do
    #     service = described_class.new(planning_application:, params:)

    #     expect {
    #       service.call
    #     }.to raise_error(NeighbourResponse::NeighbourResponseCreationService::CreateError)
    #   end
    # end
  end
end
