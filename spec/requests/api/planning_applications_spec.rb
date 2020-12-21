# frozen_string_literal: true

require "rails_helper"
require "swagger_helper"

RSpec.describe 'Planning Applications', swagger_doc: '/v1/swagger_doc.yaml', type: :request, show_exceptions: true do
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
        security [ bearerAuth: [] ]
        parameter name: :planning_application, in: :body, schema: {
            type: :object,
            properties: {
                application_type: { type: :integer, example: 1 },
                site: { type: :object,
                        properties: {
                            uprn: { type: :string, example: '100081043511' },
                            address_1: { type: :string, example: '11 Abbey Gardens' },
                            address_2: { type: :string, example: 'Southwark' },
                            town: { type: :string, example: 'London' },
                            postcode: { type: :string, example: 'SE16 3RQ' },
                          }
                        },
                description: { type: :string, example: 'Add chimnney stack' },
                payment_reference: { type: :string, example: 'PAY1' },
                ward: { type: :string, example: 'Dulwich Wood' },
                questions: { type: :object,
                             properties: {
                                 flow: { type: :object,
                                         properties: {
                                             id: { type: :string, example: '-LsXty7cOZycK0rqv8B2' },
                                             text: { type: :string, example: 'The property is' },
                                             val: { type: :string, example: 'property.buildingType' },
                                             options: {
                                               type: :array,
                                               items: { type: :object }
                                             }
                                         }
                                 }
                             }
                },
                agent_first_name: { type: :string, example: 'Jennifer' },
                agent_last_name: { type: :string, example: 'Harper' },
                agent_phone: { type: :string, example: '237878889' },
                agent_email: { type: :string, example: 'agent@example.com' },
                applicant_first_name: { type: :string, example: 'Albert' },
                applicant_last_name: { type: :string, example: 'Manteras' },
                applicant_phone: { type: :string, example: '23432325435' },
                applicant_email: { type: :string, example: 'applicant@example.com' },
                constraints: {
                  type: :array,
                  items: { type: :object }
                },
                plans: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      filename: { type: :string, example: 'https://bops-test.s3.eu-west-2.amazonaws.com/proposed-first-floor-plan.pdf' },
                      tags: { type: :string, example: 'front elevation - proposed' }
                    }
                  }
                }
              }
            },
            required: %w[site application_type]

        response '200', :valid_request do
          let(:planning_application) { { application_type: 1, status: 0, site: { uprn: "12343243" },
                                         payment_reference: 'PAY1', description: 'Add chimnney stack',
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
