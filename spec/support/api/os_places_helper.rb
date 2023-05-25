# frozen_string_literal: true

module OsPlacesHelper
  def stub_os_places_api_request_for(_local_authority, _planning_application)
    stub_request(:post, "https://api.os.uk/search/places/v1/find?key=testtest&maxresults=20&query=SE220HW").to_return(bops_api_response(200))
  end

  def stub_any_os_places_api_request
    stub_request(:get, "https://api.os.uk/search/places/v1/find?key=testtest&maxresults=20&query=SE220HW")
  end

  def os_places_api_response(status)
    status = Rack::Utils.status_code(status)

    body = '{results: [{address: "123 place"}]}'

    { status:, body: }
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(OsPlacesHelper)

    config.before do
      stub_any_os_places_api_request.to_return(os_places_api_response(:ok))
    end
  end
end
