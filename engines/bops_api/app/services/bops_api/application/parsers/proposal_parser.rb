# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class ProposalParser < BaseParser
        def parse
          {
            description: params[:description],
            boundary_geojson: params.dig("boundary", "site")&.to_json
          }
        end
      end
    end
  end
end
