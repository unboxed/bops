# frozen_string_literal: true

module OsPlacesHelper
  def stub_os_places_api_request_for(query)
    stub_request(:get, "https://api.os.uk/search/places/v1/find?key=testtest&maxresults=20&query=#{query}").to_return(os_places_api_response(200))
  end

  def stub_os_places_api_request_for_polygon(body, results = "polygon_search", offset = 0)
    stub_request(:post, "https://api.os.uk/search/places/v1/polygon?key=testtest&output_srs=EPSG:27700&srs=EPSG:27700&offset=#{offset}")
      .with(
        body:
      )
      .to_return(status: 200, body: Rails.root.join("spec/fixtures/os_places/#{results}.json").read, headers: {})
  end

  def stub_os_places_api_request_for_radius(lat, long)
    stub_request(:get, "https://api.os.uk/search/places/v1/radius?key=testtest&output_srs=EPSG:4258&point=#{lat},#{long}&radius=50&srs=EPSG:4258")
      .to_return(status: 200, body: Rails.root.join("spec/fixtures/os_places/radius_search.json").read, headers: {})
  end

  def stub_any_os_places_api_request
    stub_request(:get, "https://api.os.uk/search/places/v1/find").with(query: hash_including({}))
  end

  def os_places_api_response(status)
    status = Rack::Utils.status_code(status)

    body = "{'results': [{'address': '123 place'}]}"

    {status:, body:}
  end

  def mock_csrf_token(token = "mock")
    script = <<-JS
      if (!document.querySelector("[name='csrf-token']")) {
        let meta = document.createElement("meta")
        meta.name = "csrf-token"
        meta.content = "#{token}"
        document.head.appendChild(meta)
      }
    JS

    page.execute_script(script)
  end

  def dispatch_geojson_event(geojson)
    script = <<-JS
      const map = document.querySelector("my-map")
      const geoJSONEvent = new CustomEvent("geojsonChange", { detail: #{geojson.to_json} })
      map.dispatchEvent(geoJSONEvent)
    JS

    page.execute_script(script)
  end

  def reset_map
    script = <<-JS
      let root = document.querySelector("my-map").shadowRoot;
      let button = root.querySelector('button[title="Reset map view"][aria-label="Reset map view"]');
      if (button) {
        button.click();
      }
    JS

    page.execute_script(script)
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(OsPlacesHelper)

    config.before do |example|
      unless example.metadata[:exclude_stub_any_os_places_api_request]
        stub_any_os_places_api_request.to_return(os_places_api_response(:ok))
      end
    end
  end
end
