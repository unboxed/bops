# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class SubmissionParser < BaseParser
      def parse
        {
          session_id: params[:metadata][:id],
          params_v2: params
        }
      end
    end
  end
end
