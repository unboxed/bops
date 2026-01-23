# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class ApplicationTypeParser < BaseParser
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
        scope = :"bops_submissions.pp_to_odp_code"
        code = I18n.t(scenario, scope:, params:)

        {application_type: application_type(code)}
      end

      def parse_planx
        {application_type: application_type(params[:value])}
      end

      def application_type(code)
        config = ApplicationType::Config.find_by!(code: code)
        retried = false

        begin
          local_authority.application_types.find_or_create_by!(config_id: config.id, code: config.code, name: config.name, suffix: config.suffix)
        rescue ActiveRecord::RecordNotUnique
          if retried
            raise "Unable find or create application type"
          else
            retried = true
            retry
          end
        end
      end
    end
  end
end
