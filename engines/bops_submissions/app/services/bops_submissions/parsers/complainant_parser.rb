# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class ComplainantParser < BaseParser
      def parse
        return {} if params.blank?

        {
          complainant_address: [
            params.dig("address", "line1"),
            params.dig("address", "town"),
            params.dig("address", "postcode"),
            params.dig("address", "country")
          ].compact.compact_blank.join(", "),
          complainant_name: [params.dig("name", "first"), params.dig("name", "last")].compact.join(" "),
          complainant_email_address: params["email"],
          complainant_phone_number: params.dig("phone", "primary")
        }
      end
    end
  end
end
