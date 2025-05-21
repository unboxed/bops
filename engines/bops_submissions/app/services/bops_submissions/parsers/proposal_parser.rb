# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class ProposalParser < BaseParser
      def parse
        return {} if params.blank?
        {
          description: params.dig("applicationData", "proposalDescription", "descriptionText"),
          boundary_geojson: params.dig("polygon", "features", 0, "geometry")&.to_json
        }
      end
    end
  end
end
