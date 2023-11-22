# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "BOPS API" do
  path "/api/v2/ping" do
    get "Returns a healthcheck" do
      produces "application/json"

      response "200", "Returns a healthcheck" do
        schema "$ref" => "#/components/schemas/healthcheck"

        example "application/json", :default, {
          message: "OK",
          timestamp: "2023-11-22T20:00:00.000Z"
        }

        run_test!
      end
    end
  end
end
