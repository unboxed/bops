# frozen_string_literal: true

module BopsHelper
  BASE_URL = "bops-staging.services/planning_applications"

  def stub_bops_api_request_for(local_authority, planning_application)
    stub_request(:post, "https://#{local_authority.subdomain}.#{BASE_URL}").with(body: planning_application.params_v1).to_return(bops_api_response(200))
  end

  def stub_any_bops_api_request
    stub_request(:post, /#{BASE_URL}.*/o)
  end

  def bops_api_response(status)
    status = Rack::Utils.status_code(status)

    body = Rails.root.join("spec/fixtures/files/planx_params.json").read

    {status:, body:}
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(BopsHelper)

    config.before do
      stub_any_bops_api_request.to_return(bops_api_response(:ok))
    end
  end
end
