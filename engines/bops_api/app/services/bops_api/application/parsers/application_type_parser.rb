# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class ApplicationTypeParser < BaseParser
        def parse
          {application_type:}
        end

        private

        def application_type
          config = ApplicationType::Config.find_by!(code: params[:value])
          local_authority.application_types.find_by!(config_id: config.id)
        end
      end
    end
  end
end
