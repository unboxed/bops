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
            applicant_phone: params.dig("phone", "primary"),
            applicant_address_1: params.dig("address", "line1"),
            applicant_address_2: params.dig("address", "line2"),
            applicant_town: params.dig("address", "town"),
            applicant_county: params.dig("address", "county"),
            applicant_postcode: params.dig("address", "postcode"),
            applicant_country: params.dig("address", "country")
          }.then { |h| h.respond_to?(:compact_blank) ? h.compact_blank : h.compact }
        end
      end
    end
  end
end
