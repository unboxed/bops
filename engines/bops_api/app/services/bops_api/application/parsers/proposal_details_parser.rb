# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class ProposalDetailsParser
        attr_reader :params

        def initialize(params)
          @params = params
        end

        def parse
          return {} if params.blank?

          {
            proposal_details: params.to_json
          }
        end
      end
    end
  end
end
