# frozen_string_literal: true

require "rails_helper"

RSpec.describe NeighbourResponseCreationService, type: :service do
  include ActionDispatch::TestProcess::FixtureFile

  describe "#call" do
    let!(:planning_application) { create(:planning_application) }
    let!(:consultation) { create(:consultation, planning_application:) }

    let!(:params) do
      ActionController::Parameters.new(
        {
          "response" => "I like it",
          "address" => "123 Made up Street, E1 6LT",
          "name" => "Sophie Blog",
          "summary_tag" => "supportive",
          "files" => [""],
          "planning_application_id" => planning_application.id.to_s
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
      context "with no files attached" do
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

      context "with files attached" do
        let!(:params) do
          ActionController::Parameters.new(
            {
              "response" => "I like it",
              "address" => "123 Made up Street, E1 6LT",
              "name" => "Sophie Blog",
              "summary_tag" => "supportive",
              "files" => [
                fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-floorplan.png"), "proposed-floorplan/png"),
                fixture_file_upload(Rails.root.join("spec/fixtures/images/proposed-roofplan.pdf"), "proposed-roofplan/pdf")
              ]
            }
          )
        end

        it "creates a new neighbour response with files attached" do
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

          expect(response.documents.count).to eq 2
        end
      end
    end

    context "when unsuccessful" do
      let!(:params) do
        ActionController::Parameters.new(
          {
            "response" => "",
            "address" => "",
            "name" => "",
            "summary_tag" => "",
            "files" => [""]
          }
        )
      end

      it "raises an error" do
        expect { create_neighbour_response }.to raise_error(described_class::CreateError)
      end
    end
  end
end
