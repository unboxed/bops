# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe "BOPS API" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:southwark) { create(:local_authority, :southwark) }

  before do
    create(:api_user, :planx, token: "bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw", local_authority:)
    create(:api_user, :validation_requests_ro, name: "other", token: "bops_pDzTZPTrC7HiBiJHGEJVUSkX2PVwkk1d4mcTm9PgnQ", local_authority: southwark)
    create(:api_user, :swagger, token: "bops_CfmN6JWHTvQCzNcZGnq5kAniVSZ1MLJha68cCx_QPA", local_authority:)
  end

  path "/api/v2/ping" do
    get "Returns a healthcheck" do
      tags "Healthcheck"
      security [bearerAuth: []]
      produces "application/json"

      response "200", "with valid credentials" do
        schema "$ref" => "#/components/schemas/Healthcheck"

        example "application/json", :default, {
          message: "OK",
          timestamp: "2023-11-22T20:00:00.000Z"
        }

        let(:Authorization) { "Bearer bops_EjWSP1javBbvZFtRYiWs6y5orH4R748qapSGLNZsJw" }

        run_test!
      end

      response "200", "with valid swagger credentials" do
        schema "$ref" => "#/components/schemas/Healthcheck"

        example "application/json", :default, {
          message: "OK",
          timestamp: "2023-11-22T20:00:00.000Z"
        }

        let(:Authorization) { "Bearer bops_CfmN6JWHTvQCzNcZGnq5kAniVSZ1MLJha68cCx_QPA" }

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
    end
  end
end
