# frozen_string_literal: true

module MapitHelper
  BASE_URL = "https://mapit.mysociety.org/postcode"

  def stub_api_request_for(postcode)
    stub_request(:get, "#{BASE_URL}/#{postcode}")
  end

  def stub_any_api_request
    stub_request(:get, /#{BASE_URL}.*/)
  end

  def api_response(status, body = "default", &block)
    status = Rack::Utils.status_code(status)

    body = if block_given?
             block.call
           elsif body == "no_result"
             []
           else
             File.read(Rails.root.join("spec", "fixtures", "mapit", "#{body}.json"))
           end

    { status: status, body: body }
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(MapitHelper)

    config.before do
      stub_any_api_request.to_return(api_response(:ok))
    end
  end
end
