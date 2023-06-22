# frozen_string_literal: true

module PlanXHelper
  BASE_URL = "https://api.editor.planx.uk"

  def stub_planx_api_response_for(wkt)
    stub_request(:get, "#{BASE_URL}/gis/opensystemslab?geom=#{wkt}&analytics=false")
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(PlanXHelper)
  end
end
