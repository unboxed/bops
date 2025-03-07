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
          ApplicationType::Config.active.find_by!(code: params[:value])
        end
      end
    end
  end
end
