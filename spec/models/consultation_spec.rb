# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consultation do
  describe "#valid?" do
    let(:consultation) { build(:consultation) }

    it "is true for factory" do
      expect(consultation.valid?).to be(true)
    end
  end

  describe "validations" do
    describe "address" do
      let!(:consultation) { create(:consultation) }
      let!(:other_consultation) { create(:consultation) }
      let!(:neighbour) { create(:neighbour, address: "1, Test Lane, AAA111", consultation:) }

      it "validates uniqueness within the scope of consultation_id" do
        expect { create(:neighbour, address: "1, Test Lane, AAA111", consultation:) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Address 1, Test Lane, AAA111 has already been added.")
      end

      it "is case insensitive when validating uniqueness within the scope of consultation_id" do
        expect { create(:neighbour, address: "1, Test Lane, AAA111", consultation:) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Address 1, Test Lane, AAA111 has already been added.")
      end

      it "allows the same address for different consultations" do
        neighbour_for_other_consultation = create(:neighbour, address: "1, Test Lane, AAA111", consultation: other_consultation)

        expect(neighbour_for_other_consultation).to be_valid
      end
    end
  end

  describe "callbacks" do
    describe "::after_update #audit_letter_copy_sent!" do
      let!(:planning_application) do
        create(:planning_application, :not_started, agent_email: "agent@example.com", applicant_email: "applicant@example.com")
      end
      let!(:consultation) do
        create(:consultation, planning_application:)
      end

      context "when the letter copy sent at is updated" do
        before { Current.user = planning_application.user }

        it "creates an audit record" do
          expect do
            consultation.update(letter_copy_sent_at: Time.zone.now)
          end.to change(Audit, :count).by(1)

          expect(Audit.last).to have_attributes(
            planning_application_id: planning_application.id,
            activity_type: "neighbour_letter_copy_mail_sent",
            audit_comment: "Neighbour letter copy sent by email to agent@example.com, applicant@example.com",
            user: planning_application.user
          )
        end
      end

      context "when the letter copy sent at is not updated" do
        it "does not create an audit record" do
          expect do
            consultation.update(end_date: Time.zone.now)
          end.not_to change(Audit, :count)
        end
      end
    end
  end

  describe "#end_date_from_now" do
    let(:consultation) { create(:consultation) }

    before do
      travel_to date
    end

    context "when tomorrow is not a working day" do
      context "when it is saturday" do
        # Sat, 23 Sep 2023 13:00:00
        let(:date) { Time.zone.local(2023, 9, 23, 13) }

        it "returns the day 21 days after the next working day" do
          expect(consultation.end_date_from_now).to eq(Time.zone.local(2023, 10, 17, 9))
        end
      end

      context "when it is sunday" do
        # Sun, 24 Sep 2023 13:00:00
        let(:date) { Time.zone.local(2023, 9, 24, 13) }

        it "returns the day 21 days after the next working day" do
          expect(consultation.end_date_from_now).to eq(Time.zone.local(2023, 10, 17, 9))
        end
      end
    end

    context "when tomorrow is a working day" do
      # Wed, 20 Sep 2023 13:00:00
      let(:date) { Time.zone.local(2023, 9, 20, 13) }

      it "returns the day 21 days after the next working day" do
        expect(consultation.end_date_from_now).to eq(Time.zone.local(2023, 10, 12, 13))
      end
    end
  end

  describe "#start_deadline" do
    let(:date) { Time.zone.local(2023, 9, 20, 13) }

    before do
      travel_to date
    end

    context "when there isn't already a start date" do
      let(:consultation) { create(:consultation) }

      before do
        consultation.start_deadline
      end

      it "sets the start date to tomorrow" do
        expect(consultation.start_date).to eq(Time.zone.local(2023, 9, 21, 13))
      end

      it "sets the end date to the future" do
        expect(consultation.end_date).to eq(Time.zone.local(2023, 10, 12, 13))
      end
    end

    context "when the consultation is already started" do
      let(:consultation) { create(:consultation, :started) }

      before do
        consultation.start_deadline
      end

      it "leaves the start date alone" do
        expect(consultation.start_date).to eq(2.days.ago)
      end

      it "sets the end date to the future" do
        expect(consultation.end_date).to eq(Time.zone.local(2023, 10, 12, 13))
      end
    end
  end

  describe "#neighbour_responses_by_summary_tag" do
    let!(:consultation) { create(:consultation) }
    let!(:neighbour1) { create(:neighbour, address: "1, Random Lane, AAA111", consultation:) }
    let!(:neighbour2) { create(:neighbour, address: "2, Random Lane, AAA111", consultation:) }
    let!(:neighbour3) { create(:neighbour, address: "3, Random Lane, AAA111", consultation:) }
    let!(:objection_response) { create(:neighbour_response, neighbour: neighbour1, summary_tag: "objection") }
    let!(:supportive_response1) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
    let!(:supportive_response2) { create(:neighbour_response, neighbour: neighbour3, summary_tag: "supportive") }
    let!(:neutral_response) { create(:neighbour_response, neighbour: neighbour2, summary_tag: "neutral") }

    it "returns correct count of summary tags" do
      expect(consultation.neighbour_responses_by_summary_tag).to eq({"objection" => 1, "supportive" => 2, "neutral" => 1})
    end
  end

  describe "publicity_active?" do
    let(:consultation) { create(:consultation, end_date: Time.zone.local(2023, 9, 23, 13)) }

    before do
      travel_to date
    end

    context "when the consultation end date is not present" do
      let(:consultation) { create(:consultation) }
      let(:date) { Time.zone.local(2023, 9, 23, 13) }

      it "returns false" do
        expect(consultation.publicity_active?).to be(false)
      end
    end

    context "when the consultation end date is after now" do
      let(:date) { Time.zone.local(2023, 9, 20, 13) }

      it "returns true" do
        expect(consultation.publicity_active?).to be(true)
      end
    end

    context "when the consultation end date is before now" do
      let(:date) { Time.zone.local(2023, 9, 27, 13) }

      it "returns false" do
        expect(consultation.publicity_active?).to be(false)
      end
    end

    context "when the consultation end date is today" do
      let(:date) { Time.zone.local(2023, 9, 23, 13) }

      it "returns true" do
        expect(consultation.publicity_active?).to be(true)
      end
    end
  end

  describe "#polygon_search_and_boundary_geojson" do
    let!(:consultation) { create(:consultation, :with_polygon_search, planning_application:) }

    context "when boundary_geojson is a Feature" do
      let(:planning_application) { create(:planning_application, boundary_geojson: feature) }
      let(:feature) do
        {
          "type" => "Feature",
          "properties" => {},
          "geometry" => {
            "type" => "Polygon",
            "coordinates" => [
              [[20, 10], [30, 30], [20, 10]]
            ]
          }
        }.to_json
      end

      it "appends the feature to the features of polygon_search_geojson" do
        expect(
          consultation.polygon_search_and_boundary_geojson
        ).to eq(
          {
            "type" => "FeatureCollection",
            "features" => [
              {
                "type" => "Feature",
                "geometry" => {
                  "type" => "Polygon",
                  "coordinates" => [
                    [
                      [-0.07739927369747812, 51.501345554406896],
                      [-0.0778893839394212, 51.501002280754676],
                      [-0.07690508968054104, 51.50102474569704],
                      [-0.07676672973966252, 51.50128963605792],
                      [-0.07739927369747812, 51.501345554406896]
                    ]
                  ]
                },
                "properties" => {
                  color: "#d870fc"
                }
              },
              {
                "type" => "Feature",
                "properties" => {},
                "geometry" => {
                  "type" => "Polygon",
                  "coordinates" => [
                    [
                      [20, 10],
                      [30, 30],
                      [20, 10]
                    ]
                  ]
                }
              }
            ]
          }
        )
      end
    end

    context "when planning_application.boundary_geojson is a FeatureCollection" do
      let(:planning_application) { create(:planning_application, boundary_geojson: feature_collection) }
      let(:feature_collection) do
        {
          "type" => "FeatureCollection",
          "features" => [
            {
              "type" => "Feature",
              "properties" => {},
              "geometry" => {
                "type" => "Polygon",
                "coordinates" => [
                  [[30, 10], [40, 40], [30, 10]]
                ]
              }
            }
          ]
        }.to_json
      end

      it "concatenates the features with the features of polygon_search_geojson" do
        expect(
          consultation.polygon_search_and_boundary_geojson
        ).to eq(
          {
            "type" => "FeatureCollection",
            "features" => [
              {
                "type" => "Feature",
                "geometry" => {
                  "type" => "Polygon",
                  "coordinates" => [
                    [
                      [-0.07739927369747812, 51.501345554406896],
                      [-0.0778893839394212, 51.501002280754676],
                      [-0.07690508968054104, 51.50102474569704],
                      [-0.07676672973966252, 51.50128963605792],
                      [-0.07739927369747812, 51.501345554406896]
                    ]
                  ]
                },
                "properties" => {
                  color: "#d870fc"
                }
              },
              {
                "type" => "Feature",
                "properties" => {},
                "geometry" => {
                  "type" => "Polygon",
                  "coordinates" => [
                    [
                      [30, 10],
                      [40, 40],
                      [30, 10]
                    ]
                  ]
                }
              }
            ]
          }
        )
      end
    end

    context "when boundary_geojson is nil" do
      let(:planning_application) { create(:planning_application, boundary_geojson: nil) }

      it "returns polygon_search_geojson" do
        expect(consultation.polygon_search_and_boundary_geojson).to eq(
          {
            "type" => "FeatureCollection",
            "features" => [
              {
                "type" => "Feature",
                "geometry" => {
                  "type" => "Polygon",
                  "coordinates" => [
                    [
                      [-0.07739927369747812, 51.501345554406896],
                      [-0.0778893839394212, 51.501002280754676],
                      [-0.07690508968054104, 51.50102474569704],
                      [-0.07676672973966252, 51.50128963605792],
                      [-0.07739927369747812, 51.501345554406896]
                    ]
                  ]
                },
                "properties" => {
                  color: "#d870fc"
                }
              }
            ]
          }
        )
      end
    end

    context "when polygon_search is nil" do
      let!(:consultation) { create(:consultation, planning_application:) }
      let(:planning_application) { create(:planning_application) }

      it "returns nil" do
        expect(consultation.polygon_search_and_boundary_geojson).to be_nil
      end
    end

    context "when boundary_geojson is an invalid GeoJSON type" do
      let(:planning_application) { create(:planning_application) }

      it "raises an error" do
        allow(planning_application).to receive(:boundary_geojson).and_return({"type" => "InvalidType"}.to_json)

        expect { consultation.polygon_search_and_boundary_geojson }.to raise_error(/Invalid GeoJSON type/)
      end
    end
  end
end
