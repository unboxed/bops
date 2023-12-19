# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  let(:local_authority) { create(:local_authority, :default) }

  before do
    create(:api_user, :planx, token: "bRPkCPjaZExpUYptBJDVFzss", local_authority:)
    create(:api_user, name: "other", token: "pUYptBJDVFzssbRPkCPjaZEx")
    create(:api_user, :swagger, token: "tBJDVFzPjabRPkCUYpZExpss", local_authority:)
  end

  path "/api/v2/ping" do
    get "Returns a healthcheck" do
      security [bearerAuth: []]
      produces "application/json"

      response "200", "with valid credentials" do
        schema "$ref" => "#/components/schemas/Healthcheck"

        example "application/json", :default, {
          message: "OK",
          timestamp: "2023-11-22T20:00:00.000Z"
        }

        let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }

        run_test!
      end

      response "200", "with valid swagger credentials" do
        schema "$ref" => "#/components/schemas/Healthcheck"

        example "application/json", :default, {
          message: "OK",
          timestamp: "2023-11-22T20:00:00.000Z"
        }

        let(:Authorization) { "Bearer tBJDVFzPjabRPkCUYpZExpss" }

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

        let(:Authorization) { "Bearer pUYptBJDVFzssbRPkCPjaZEx" }

        run_test!
      end
    end
  end
end
