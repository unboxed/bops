# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class PreAssessmentParser
        attr_reader :params

        def initialize(params)
          @params = params
        end

        def parse
          return {} if params.blank?

          {
            result_heading: params.first[:value],
            result_description: params.first[:description]
          }
        end
      end
    end
  end
end
