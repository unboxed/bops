# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class ProposalParser < BaseParser
      def parse
        return {} if params.blank?
        {
          description: params.dig("proposalDescription", "descriptionText"),
          boundary_geojson: params.dig("polyglon", "features", "geometry")&.to_json
        }
      end
    end
  end
end
