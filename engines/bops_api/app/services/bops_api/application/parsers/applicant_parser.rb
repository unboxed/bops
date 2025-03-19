# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class ApplicantParser < BaseParser
        def parse
          {
            applicant_first_name: params.dig("name", "first"),
            applicant_last_name: params.dig("name", "last"),
            applicant_email: params[:email],
            applicant_phone: params.dig("phone", "primary")
          }
        end
      end
    end
  end
end
