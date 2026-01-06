# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class PreAssessmentParser < BaseParser
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
