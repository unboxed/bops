# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class AgentParser < BaseParser
      FIELD_MAP = {
        "PlanX" => {
          agent_first_name: ->(p) { p.dig("name", "first") },
          agent_last_name: ->(p) { p.dig("name", "last") },
          agent_email: ->(p) { p[:email] },
          agent_phone: ->(p) { p.dig("phone", "primary") },
          agent_company_name: ->(p) { p.dig("company", "name") },
          agent_address_1: ->(p) { p.dig("address", "line1") },
          agent_address_2: ->(p) { p.dig("address", "line2") },
          agent_town: ->(p) { p.dig("address", "town") },
          agent_postcode: ->(p) { p.dig("address", "postcode") },
          agent_county: ->(p) { p.dig("address", "county") },
          agent_country: ->(p) { p.dig("address", "country") }
        },
        "Planning Portal" => {
          agent_first_name: ->(p) { p["personGivenName"] },
          agent_last_name: ->(p) { p["personFamilyName"] },
          agent_email: ->(p) { p["emailAddress"] },
          agent_phone: ->(p) { p["telNationalNumber"] }
        }
      }.freeze

      def parse
        return {} if params.blank?

        mapper = FIELD_MAP.fetch(source) do
          raise "Unknown source: #{source.inspect}"
        end

        mapper.transform_values { |parser| parser.call(params) }
      end
    end
  end
end
