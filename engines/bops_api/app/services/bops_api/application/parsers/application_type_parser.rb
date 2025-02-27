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
          {application_type:}
        end

        private

        def application_type
          application_type = ApplicationType.active.find_by!(code: params[:value])
          params[:local_authority].local_authority_application_types.find_or_create_by!(application_type_id: application_type.id)
          application_type
        end
      end
    end
  end
end
