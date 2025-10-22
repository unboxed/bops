# frozen_string_literal: true

require "base64"

module BopsCore
  module AssetsHelper
    def data_uri(type, data)
      "data:#{type};base64,#{Base64.strict_encode64(data)}"
    end
  end
end
