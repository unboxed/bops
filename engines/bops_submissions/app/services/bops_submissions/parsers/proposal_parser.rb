# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class ProposalParser < BaseParser
      def parse
        return {} if params.blank?

        case source
        when "Planning Portal"
          parse_planning_portal
        when "PlanX"
          parse_planx
        end
      end

      private

      def parse_planning_portal
        scenario = params.dig("applicationScenario", "scenarioNumber")
        scope = :"bops_submissions.pp_to_description"
        default = params.dig("applicationHeader", "description")
        description = I18n.t(scenario, scope:, params:, default:)

        {
          description: description,
          boundary_geojson: params.dig("polygon")
        }
      end

      def parse_planx
        {
          description: params[:description],
          boundary_geojson: params.dig("boundary", "site")
        }
      end
    end
  end
end
