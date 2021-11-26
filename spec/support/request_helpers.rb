# frozen_string_literal: true

module Requests
  # this allows a shortcut to JSON.parse the response.body
  # NOTE: not convinced the overhead is necessary
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end

    def json_time_format(time)
      time.iso8601(3) if time.present?
    end

    def sort_by_id(response)
      response.sort_by! { |k| k["id"] }
    end
  end
end

RSpec.configure do |config|
  config.include Requests::JsonHelpers, type: :request
end
