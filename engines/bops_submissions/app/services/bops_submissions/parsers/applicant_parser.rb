# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class ApplicantParser < BaseParser
      def parse
        {
          applicant_first_name: params["personGivenName"],
          applicant_last_name: params["personFamilyName"],
          applicant_email: params["emailAddress"],
          applicant_phone: params["telNationalNumber"]
        }
      end
    end
  end
end
