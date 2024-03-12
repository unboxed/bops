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
          {application_type:, work_status:}.compact
        end

        private

        def work_status
          case params[:value]
          when "ldc.existing"
            "existing"
          when "ldc.proposed"
            "proposed"
          end
        end

        def application_type
          ApplicationType.active.find_by!(code: params[:value])
        end
      end
    end
  end
end
