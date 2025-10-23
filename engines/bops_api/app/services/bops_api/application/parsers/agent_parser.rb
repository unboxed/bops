# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class AgentParser < BaseParser
        def parse
          return {} if params.blank?

          {
            agent_first_name: params.dig("name", "first"),
            agent_last_name: params.dig("name", "last"),
            agent_email: params[:email],
            agent_phone: params.dig("phone", "primary"),
            agent_company_name: params.dig("company", "name"),
            agent_address_1: params.dig("address", "line1"),
            agent_address_2: params.dig("address", "line2"),
            agent_town: params.dig("address", "town"),
            agent_postcode: params.dig("address", "postcode"),
            agent_county: params.dig("address", "county"),
            agent_country: params.dig("address", "country")
          }
        end
      end
    end
  end
end
