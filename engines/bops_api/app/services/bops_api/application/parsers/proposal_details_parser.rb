# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class ProposalDetailsParser < BaseParser
        def parse
          return {} if params.blank?

          {
            proposal_details: params
          }
        end
      end
    end
  end
end
