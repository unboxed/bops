# frozen_string_literal: true

module PaapiHelper
  BASE_URL = "https://staging.paapi.services/api/v1/planning_applications"

  def stub_paapi_api_request_for(uprn)
    stub_request(:get, "#{BASE_URL}/?uprn=#{uprn}")
  end

  def paapi_api_response(status, body = "100081043511")
    status = Rack::Utils.status_code(status)

    body = if body == "no_result"
             []
           else
             Rails.root.join("spec", "fixtures", "paapi", "#{body}.json").read
           end

    { status: status, body: body }
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(PaapiHelper)

    config.before do
      stub_paapi_api_request_for("100081043511").to_return(paapi_api_response(:ok))
      stub_paapi_api_request_for("10008104351").to_return(paapi_api_response(:not_found, "no_result"))
    end
  end
end
