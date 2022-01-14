# frozen_string_literal: true

require Rails.root.join "spec/support/api/mapit_helpers"

World(MapitHelper)

Before do
  stub_any_api_request.to_return(api_response(:ok))
end
