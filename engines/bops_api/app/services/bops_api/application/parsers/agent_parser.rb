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
            agent_business_name: params.dig("company", "name")
          }
        end
      end
    end
  end
end
