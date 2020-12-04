# frozen_string_literal: true

require "rails_helper"
require "swagger_helper"

RSpec.describe 'Planning Applications', swagger_doc: '/api-docs/swagger_doc.json', type: :request, show_exceptions: true do
  path '/api/v1/planning_applications' do
      # it "should return a 200 response" do
      get 'Retrieves all determined planning applications' do
        produces 'application/json'

        response '200', 'All determined planning applications' do
          run_test!
        end
      # end
    end

      # it "should return valid responses when new application is created" do
      #   api_user = create(:api_user)
      post 'Create new planning application' do
        consumes 'application/json'
        security [ Token: [] ]
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
                constraints: { type: :string },
                plans: [{
                            filename: { type: :string },
                            tags: { type: :string },
                        }],
                }
            },
            required: %w[site application_type status]

        response '200', :valid_request do
          let(:planning_application) { { application_type: 1, status: 0, site: { uprn: "12343243" },
                                         description: 'Add chimnney stack',
                                         questions: JSON.parse(File.read(Rails.root.join("spec/fixtures/files/permitted_development.json"))) }}
          let(:api_user) { create(:api_user) }
          let(:Authorization) { "Bearer #{api_user.token}" }
          run_test!
        end

        response '400', :invalid_request do
          let(:planning_application) { '{"dfsdafsad": "dsfdsf"}' }
          let(:api_user) { create(:api_user) }
          let(:Authorization) { "Bearer #{api_user.token}" }
          run_test!
        end

        response '401', :unauthorized_user do
          let(:planning_application) { { application_type: 1, status: 0, site: { uprn: "12343243" }, description: 'Add chimnney stack' } }
          let(:api_user) { create(:api_user) }
          let(:Authorization) { "Bearer 343erdsfqwerf" }
          run_test!
        end
      end
    # end
  end
end
