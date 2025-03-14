# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  let(:config) { Rails.configuration }
  let(:local_authority) { create(:local_authority, :default) }
  let(:southwark) { create(:local_authority, :southwark) }
  let(:application_type) { create(:application_type, local_authority:) }

  before do
    create(:api_user, token: "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw", local_authority:)
    create(:api_user, name: "other", token: "bops_pDzTZPTrC7HiBiJHGEJVUSkX2PVwkk1d4mcTm9PgnQ", local_authority: southwark)

    create(:application_type_config, :ldc_existing)
    create(:application_type_config, :ldc_proposed)
    create(:application_type_config, :listed)
    create(:application_type_config, :land_drainage)
    create(:application_type_config, :pa_part1_classA)
    create(:application_type_config, :pa_part_14_class_j)
    create(:application_type_config, :pa_part_20_class_ab)
    create(:application_type_config, :pa_part_3_class_ma)
    create(:application_type_config, :pa_part7_classM)
    create(:application_type_config, :minor)
    create(:application_type_config, :major)
    create(:application_type_config, :pre_application)

    Rails.configuration.os_vector_tiles_api_key = "testtest"
  end

  let(:Authorization) { "Bearer bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }
  let(:planning_application) { example_fixture("application/planningPermission/fullHouseholder.json") }
  let(:send_email) { "true" }

  let!(:planning_applications) { create_list(:planning_application, 8, :published, local_authority:, application_type:) }
  let!(:determined_planning_applications) { create_list(:planning_application, 3, :determined, local_authority:, application_type:) }

  let!(:householder) { create(:application_type, :householder, local_authority:) }
  let!(:householder_planning_applications) { create_list(:planning_application, 4, :with_boundary_geojson_features, local_authority:, application_type: householder) }

  let(:submission) { create(:planx_planning_data, params_v2: example_fixture("application/planningPermission/fullHouseholder.json")) }
  let(:planning_application_with_submission) { create(:planning_application, :planning_permission, local_authority:, planx_planning_data: submission) }

  let(:page) { 2 }
  let(:maxresults) { 5 }
  let("ids[]") { [] }

  path "/api/v2/planning_applications" do
    post "Creates a new plannning application" do
      tags "Planning applications"
      security [bearerAuth: []]
      consumes "application/json"
      produces "application/json"

      parameter name: :planning_application, in: :body, schema: {
        "$ref": "#/components/schemas/Submission"
      }

      parameter name: :send_email, in: :query, schema: {
        enum: %w[true false],
        default: "true"
      }, required: false

      [
        %w[DRN application/landDrainageConsent.json],
        %w[LBC application/listedBuildingConsent.json],
        %w[LDCE application/lawfulDevelopmentCertificate/existing.json],
        %w[LDCP application/lawfulDevelopmentCertificate/proposed.json],
        %w[HAPP application/planningPermission/fullHouseholder.json],
        %w[HAPC application/planningPermission/fullHouseholderInConservationArea.json],
        %w[MAJOR application/planningPermission/major.json],
        %w[MINOR application/planningPermission/minor.json],
        %w[PA20AB application/priorApproval/buildHomes.json],
        %w[PA3MA application/priorApproval/convertCommercialToHome.json],
        %w[PA7M application/priorApproval/extendUniversity.json],
        %w[PA1A application/priorApproval/largerExtension.json],
        %w[PA14J application/priorApproval/solarPanels.json],
        %w[PRE preApplication/preApp.json]
      ].each do |suffix, fixture|
        value = example_fixture(fixture, symbolize_names: true)
        name = value.dig(:data, :application, :type, :value)
        summary = value.dig(:data, :application, :type, :description)

        request_body_example(value:, name:, summary:)

        response "200", "with a valid request" do
          schema "$ref" => "#/components/schemas/SubmissionResponse"

          example "application/json", summary, {
            id: "BUC-23-00100-#{suffix}",
            message: "Application successfully created"
          }

          let(:planning_application) { example_fixture(fixture) }

          run_test! do
            [
              ["myPlans.pdf", "planx/odp/myPlans.pdf", "application/pdf"],
              ["other.pdf", "planx/odp/other.pdf", "application/pdf"],
              ["elevations.pdf", "planx/odp/elevations.pdf", "application/pdf"],
              ["floor_plans.pdf", "planx/odp/floor_plans.pdf", "application/pdf"],
              ["correspondence.pdf", "planx/odp/correspondence.pdf", "application/pdf"],
              ["heritageStatement.pdf", "planx/odp/heritageStatement.pdf", "application/pdf"],
              ["invoice.pdf", "planx/odp/invoice.pdf", "application/pdf"],
              ["test document.pdf", "planx/odp/test document.pdf", "application/pdf"],
              ["location plan_proposed_01.jpg", "planx/odp/location plan_proposed_01.jpg", "image/jpeg"],
              ["Site-location-plan-example.pdf", "planx/odp/Site-location-plan-example.pdf", "application/pdf"],
              ["Rooftype_pyramid@4x.png", "planx/odp/Rooftype_pyramid@4x.png", "image/png"],
              ["elevations_existing_01.jpg", "planx/odp/elevations_existing_01.jpg", "image/jpeg"],
              ["elevations_proposed_01.jpg", "planx/odp/elevations_proposed_01.jpg", "image/jpeg"],
              ["Elevations-best-practice.pdf", "planx/odp/Elevations-best-practice.pdf", "application/pdf"]
            ].each do |file, fixture, content_type|
              stub_request(:get, %r{\Ahttps://api.editor.planx.dev/file/private/\w+/#{Regexp.escape(file)}\z})
                .with(headers: {"Api-Key" => "G41sAys9uPMUVBH5WUKsYE4H"})
                .to_return(
                  status: 200,
                  body: file_fixture(fixture).read,
                  headers: {"Content-Type" => content_type}
                )
            end

            latitude = value.dig(:data, :property, :address, :latitude)
            longitude = value.dig(:data, :property, :address, :longitude)
            stub_os_places_api_request_for_radius(latitude, longitude)

            perform_enqueued_jobs
          end
        end
      end

      response "400", "with an invalid request" do
        schema "$ref" => "#/components/schemas/BadRequestError"

        example "application/json", :default, {
          error: {
            code: 400,
            message: "Bad Request",
            detail: "We couldn’t process your request because some information is missing or incorrect."
          }
        }

        let(:planning_application) do
          {
            "metadata" => {
              "schema" => "https://theopensystemslab.github.io/digital-planning-data-schemas/v0.3.0/schema.json"
            }
          }
        end

        run_test!
      end

      response "401", "with missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        example "application/json", :default, {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }

        let(:Authorization) { "Bearer invalid-credentials" }

        run_test!
      end

      response "401", "with a token from another api user" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        example "application/json", :default, {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }

        let(:Authorization) { "Bearer bops_pDzTZPTrC7HiBiJHGEJVUSkX2PVwkk1d4mcTm9PgnQ" }

        run_test!
      end

      response "403", "when the endpoint is disabled" do
        before do
          allow(BopsApi::Application::CreationService).to receive(:new).and_raise(BopsApi::Errors::NotPermittedError)
        end

        schema "$ref" => "#/components/schemas/ForbiddenError"

        example "application/json", :default, {
          error: {
            code: 403,
            message: "Forbidden",
            detail: "Creating planning applications using this endpoint is not permitted in production"
          }
        }

        run_test!
      end

      response "422", "when an application is invalid" do
        schema "$ref" => "#/components/schemas/UnprocessableEntityError"

        example "application/json", :default, {
          error: {
            code: 422,
            message: "Unprocessable Entity",
            detail: "Planning application is invalid"
          }
        }

        let(:planning_application) { json_fixture("v2/invalid_planning_permission.json") }

        run_test!
      end

      response "500", "when an internal server error occurs" do
        before do
          planning_application = PlanningApplication.new
          exception = ActiveRecord::ConnectionTimeoutError.new("Couldn’t connect to the database")

          allow(PlanningApplication).to receive(:new).and_return(planning_application)
          allow(planning_application).to receive(:save!).and_raise(exception)
        end

        schema "$ref" => "#/components/schemas/InternalServerError"

        example "application/json", :default, {
          error: {
            code: 500,
            message: "Internal Server Error",
            detail: "Couldn’t connect to the database"
          }
        }

        run_test!
      end

      context "when validating against submission schema definitions" do
        schema = BopsApi::Schemas.find!("submission", version: BopsApi::Schemas::DEFAULT_ODP_VERSION).value

        it "validates document tags" do
          schema_tags = schema["definitions"]["FileType"]["anyOf"].map { |entry| entry["properties"]["value"]["const"] }
          missing_tags = schema_tags - Document::TAGS

          expect(missing_tags).to be_empty, "Missing tags in schema for: #{missing_tags.join(", ")}"
        end

        it "validates application types" do
          schema_types = schema["definitions"]["ApplicationType"]["anyOf"].map { |entry| entry["properties"]["value"]["const"] }
          missing_types = schema_types - ApplicationType::Config::CURRENT_APPLICATION_TYPES

          expect(missing_types).to be_empty, "Missing application types in schema for: #{missing_types.join(", ")}"
        end
      end
    end
  end

  path "/api/v2/planning_applications" do
    get "Retrieves planning applications" do
      tags "Planning applications"
      security [bearerAuth: []]
      produces "application/json"

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }, required: false

      parameter name: "ids[]", in: :query, schema: {
        type: :array,
        items: {
          type: :integer
        }
      }

      response "200", "returns planning applications" do
        example "application/json", :default, api_json_fixture("planning_applications/index.json")

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 2,
              "results" => 5,
              "from" => 6,
              "to" => 10,
              "total_pages" => 3,
              "total_results" => 15
            }
          )
        end
      end

      response "200", "returns planning applications with given ids" do
        example "application/json", :ids, api_json_fixture("planning_applications/index.json")

        let(:page) { 1 }
        let("ids[]") { planning_applications.take(4).map(&:id) }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 4,
              "total_pages" => 1,
              "total_results" => 4
            }
          )
        end
      end

      response "401", "with missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        example "application/json", :default, {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }

        let(:Authorization) { "Bearer invalid-credentials" }

        run_test!
      end
    end
  end

  path "/api/v2/planning_applications/determined" do
    get "Retrieves determined planning applications" do
      tags "Planning applications"
      produces "application/json"

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }, required: false

      parameter name: "ids[]", in: :query, style: :form, explode: true, schema: {
        type: :array,
        items: {
          type: :integer
        }
      }

      response "200", "returns determined planning applications" do
        example "application/json", :default, api_json_fixture("planning_applications/determined.json")

        let(:page) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 3,
              "total_pages" => 1,
              "total_results" => 3
            }
          )

          statuses = data["data"].pluck("status").uniq
          expect(statuses).to eq(["determined"])
        end
      end

      response "200", "returns determined planning applications with given ids" do
        example "application/json", :ids, api_json_fixture("planning_applications/determined.json")

        let(:page) { 1 }
        let("ids[]") { determined_planning_applications[0, 2].map(&:id) }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 1,
              "results" => 5,
              "from" => 1,
              "to" => 2,
              "total_pages" => 1,
              "total_results" => 2
            }
          )
        end
      end
    end
  end

  path "/api/v2/planning_applications/{reference}" do
    get "Retrieves a planning application" do
      tags "Planning applications"
      security [bearerAuth: []]
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        oneOf: [
          {type: :string, pattern: "\d{2}-\d{5}-[A-Za-z0-9]+"},
          {type: :integer}
        ],
        description: "The planning application reference or ID"
      }

      response "200", "returns a planning application given an ID" do
        example "application/json", :default, api_json_fixture("planning_applications/show.json")

        let(:planning_application) { planning_applications.first }
        let(:reference) { planning_application.id }

        let!(:document) { create(:document, :with_tags, planning_application:, validated: true, publishable: true) }

        context "when use_signed_cookies is false" do
          before do
            allow(config).to receive(:use_signed_cookies).and_return(false)
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["id"]).to eq(reference)
            expect(data["description"]).to eq(planning_application.description)

            expect(data["documents"]).to match_array([
              a_hash_including("url" => "http://uploads.example.com/#{document.blob_key}")
            ])
          end
        end

        context "when use_signed_cookies is true" do
          before do
            allow(config).to receive(:use_signed_cookies).and_return(true)
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["id"]).to eq(reference)
            expect(data["description"]).to eq(planning_application.description)

            expect(data["documents"]).to match_array([
              a_hash_including("url" => "http://planx.example.com/files/#{document.blob_key}")
            ])
          end
        end
      end

      response "200", "returns a planning application given a reference" do
        example "application/json", :default, api_json_fixture("planning_applications/show.json")

        let(:planning_application) { planning_applications.first }
        let(:reference) { planning_application.reference }

        let!(:document) { create(:document, :with_tags, planning_application:, validated: true, publishable: true) }

        context "when use_signed_cookies is false" do
          before do
            allow(config).to receive(:use_signed_cookies).and_return(false)
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["reference"]).to eq(planning_application.reference)
            expect(data["description"]).to eq(planning_application.description)

            expect(data["documents"]).to match_array([
              a_hash_including("url" => "http://uploads.example.com/#{document.blob_key}")
            ])
          end
        end

        context "when use_signed_cookies is true" do
          before do
            allow(config).to receive(:use_signed_cookies).and_return(true)
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["reference"]).to eq(planning_application.reference)
            expect(data["description"]).to eq(planning_application.description)

            expect(data["documents"]).to match_array([
              a_hash_including("url" => "http://planx.example.com/files/#{document.blob_key}")
            ])
          end
        end
      end

      response "404", "when no planning application can be found" do
        schema "$ref" => "#/components/schemas/NotFoundError"

        example "application/json", :default, {
          error: {
            code: 404,
            message: "Not Found",
            detail: "Couldn't find PlanningApplication with 'id'=734837"
          }
        }

        let(:reference) { 734837 }

        run_test!
      end
    end
  end

  path "/api/v2/planning_applications/{reference}/submission" do
    it "validates successfully against the example applicationSubmission json" do
      resolved_schema = load_and_resolve_schema(name: "applicationSubmission", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)

      schemer = JSONSchemer.schema(resolved_schema)
      example_json = example_fixture("applicationSubmission.json")
      expect(schemer.valid?(example_json)).to eq(true)
    end

    get "Retrieves the planning application submission given a reference" do
      tags "Planning applications"
      security [bearerAuth: []]
      produces "application/json"

      parameter name: :reference, in: :path, schema: {
        type: :string,
        description: "The planning application reference"
      }

      response "200", "returns planning application submission when searching by the reference" do
        example "application/json", :default, example_fixture("applicationSubmission.json")
        schema "$ref" => "#/components/schemas/ApplicationSubmission"

        let(:reference) { planning_application_with_submission.reference }
        let(:redacted_submission) { BopsApi::Application::SubmissionRedactionService.new(planning_application: planning_application_with_submission).call }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["application"]["reference"]).to eq(reference)
          expect(data["submission"]).to eq(redacted_submission)
        end
      end

      response "401", "with missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/UnauthorizedError"

        example "application/json", :default, {
          error: {
            code: 401,
            message: "Unauthorized"
          }
        }

        let(:Authorization) { "Bearer invalid-credentials" }
        let(:reference) { planning_applications.first.reference }

        run_test!
      end
    end
  end

  path "/api/v2/planning_applications/search" do
    get "Retrieves planning applications based on a search criteria" do
      tags "Planning applications"
      security [bearerAuth: []]
      produces "application/json"

      parameter name: :page, in: :query, schema: {
        type: :integer,
        default: 1
      }, required: false

      parameter name: :maxresults, in: :query, schema: {
        type: :integer,
        default: 10
      }, required: false

      parameter name: "q", in: :query, schema: {
        type: :string,
        description: "Search by reference or description"
      }

      it "validates successfully against the example search json" do
        resolved_schema = load_and_resolve_schema(name: "search", version: BopsApi::Schemas::DEFAULT_ODP_VERSION)
        schemer = JSONSchemer.schema(resolved_schema)
        example_json = example_fixture("search.json")

        expect(schemer.valid?(example_json)).to eq(true)
      end

      response "200", "returns planning applications when searching by a reference or description" do
        schema "$ref" => "#/components/schemas/Search"
        example "application/json", :default, example_fixture("search.json")

        let(:page) { 2 }
        let(:maxresults) { 2 }
        let(:q) { "HAPP" }

        run_test! do |response|
          data = JSON.parse(response.body)
          metadata = data["metadata"]

          expect(metadata).to eq(
            {
              "page" => 2,
              "results" => 2,
              "from" => 3,
              "to" => 4,
              "total_pages" => 2,
              "total_results" => 4
            }
          )
        end
      end
    end
  end
end
