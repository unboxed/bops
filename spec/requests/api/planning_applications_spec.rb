# frozen_string_literal: true

require "rails_helper"
require "swagger_helper"

RSpec.describe 'Planning Applications', swagger_doc: 'api/swagger_doc.json', type: :request, show_exceptions: true do
  path '/api/v1/planning_applications' do
      get 'Retrieves all determined planning applications' do
        produces 'application/json'

        response '200', 'All determined planning applications' do
          run_test!
        end
      end

      post 'Create new planning application' do
        consumes 'application/json'
        parameter name: :planning_application, in: :body, schema: {
            type: :object,
            properties: {
                application_type: { type: :integer },
                status: { type: :integer },
                site: { type: :object,
                        properties: {
                            uprn: { type: :string },
                            address_1: { type: :string },
                            address_2: { type: :string },
                            town: { type: :string },
                            postcode: { type: :string },
                          }
                        },
                description: { type: :string },
                ward: { type: :string },
                user_id: { type: :integer },
                questions: { type: :string },
                agent_first_name: { type: :string },
                agent_last_name: { type: :string },
                agent_phone: { type: :string },
                agent_email: { type: :string },
                applicant_first_name: { type: :string },
                applicant_last_name: { type: :string },
                applicant_phone: { type: :string },
                applicant_email: { type: :string },
                }
            },
            required: %w[site application_type status]

        response '200', :valid_request do
          let(:planning_application) { { application_type: 1, status: 0, site: { uprn: "12343243" }, description: 'Add chimnney stack' } }
          run_test!
        end

        response '400', :invalid_request do
          let(:planning_application) { '{"dfsdafsad": "dsfdsf"}' }
          run_test!
        end
      end
  end
end
