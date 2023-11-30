# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class ApplicationTypeParser
        attr_reader :params

        def initialize(params)
          @params = params
        end

        def parse
          {
            application_type: ApplicationType.find_by!(name: application_type),
            work_status: work_status
          }.compact
        end

        private

        def application_type
          case params[:value]
          when "pp.full.householder"
            "planning_permission"
          when "pa.part1.classA"
            "prior_approval"
          when "ldc.existing", "ldc.proposed"
            "lawfulness_certificate"
          end
        end

        def work_status
          case params[:value]
          when "ldc.existing"
            "existing"
          when "ldc.proposed"
            "proposed"
          end
        end
      end
    end
  end
end
