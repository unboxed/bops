# frozen_string_literal: true

module MapitHelper
  BASE_URL = "https://mapit.mysociety.org/postcode"

  def stub_mapit_api_request_for(postcode)
    stub_request(:get, "#{BASE_URL}/#{postcode}")
  end

  def stub_any_mapit_api_request
    stub_request(:get, /#{BASE_URL}.*/o)
  end

  def mapit_api_response(status, body = "default", &block)
    status = Rack::Utils.status_code(status)

    body = if block
             yield
           elsif body == "no_result"
             []
           else
             Rails.root.join("spec", "fixtures", "mapit", "#{body}.json").read
           end

    { status: status, body: body }
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(MapitHelper)

    config.before do
      stub_any_mapit_api_request.to_return(mapit_api_response(:ok))
    end
  end
end
