# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class ProposalParser
        attr_reader :params

        def initialize(params)
          @params = params
        end

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
