# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class SubmissionParser
        attr_reader :params

        def initialize(params)
          @params = params
        end

        def parse
          {
            session_id: params[:metadata][:id],
            params_v2: params
          }
        end
      end
    end
  end
end
