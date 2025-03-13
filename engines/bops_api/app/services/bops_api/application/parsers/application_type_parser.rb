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
end
