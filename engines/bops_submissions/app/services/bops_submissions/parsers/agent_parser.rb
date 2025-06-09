# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class AgentParser < BaseParser
      def parse
        return {} if params.blank?

        {
          agent_first_name: params["personGivenName"],
          agent_last_name: params["personFamilyName"],
          agent_email: params["emailAddress"],
          agent_phone: params["telNationalNumber"]
        }
      end
    end
  end
end
