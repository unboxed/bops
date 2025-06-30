# frozen_string_literal: true

require_relative "../../../swagger_helper"

RSpec.describe "BOPS public API application types" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:application_type) { create(:application_type, :ldc_proposed) }

  before do
    allow_any_instance_of(BopsApi::V2::PublicController).to receive(:current_local_authority).and_return(local_authority)
  end

  path "/api/v2/public/application_types" do
    get "List all application types for the current local authority" do
      tags "Application types"
      produces "application/json"

      response "200", "array of application types" do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              name: {type: :string, example: "lawfulness_certificate"},
              code: {type: :string, example: "ldc.proposed"},
              suffix: {type: :string, example: "LDCP"}
            },
            required: %w[name code suffix]
          }

        run_test!
      end
    end
  end
end
