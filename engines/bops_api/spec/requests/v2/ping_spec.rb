# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  before do
    create(:local_authority, :default)
    create(:api_user, token: "bRPkCPjaZExpUYptBJDVFzss")
  end

  path "/api/v2/ping" do
    get "Returns a healthcheck" do
      security [bearerAuth: []]
      produces "application/json"

      response "200", "Returns a healthcheck" do
        schema "$ref" => "#/components/schemas/healthcheck"

        example "application/json", :default, {
          message: "OK",
          timestamp: "2023-11-22T20:00:00.000Z"
        }

        let(:Authorization) { "Bearer bRPkCPjaZExpUYptBJDVFzss" }

        run_test!
      end

      response "401", "Missing or invalid credentials" do
        schema "$ref" => "#/components/schemas/unauthorized"

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
end