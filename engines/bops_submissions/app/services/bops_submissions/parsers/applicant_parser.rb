# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class ApplicantParser < BaseParser
      FIELD_MAP = {
        "Planning Portal" => {
          applicant_first_name: ->(p) { p["personGivenName"] },
          applicant_last_name: ->(p) { p["personFamilyName"] },
          applicant_email: ->(p) { p["emailAddress"] },
          applicant_phone: ->(p) { p["telNationalNumber"] }
        },
        "PlanX" => {
          applicant_first_name: ->(p) { p.dig("name", "first") },
          applicant_last_name: ->(p) { p.dig("name", "last") },
          applicant_email: ->(p) { p[:email] || p["email"] },
          applicant_phone: ->(p) { p.dig("phone", "primary") },
          applicant_address_1: ->(p) { p.dig("address", "line1") },
          applicant_address_2: ->(p) { p.dig("address", "line2") },
          applicant_town: ->(p) { p.dig("address", "town") },
          applicant_county: ->(p) { p.dig("address", "county") },
          applicant_postcode: ->(p) { p.dig("address", "postcode") },
          applicant_country: ->(p) { p.dig("address", "country") }
        }
      }.freeze

      def parse
        return {} if params.blank?

        mapper = FIELD_MAP.fetch(source) { raise "Unknown source: #{source.inspect}" }

        mapper.each_with_object({}) do |(key, lambda_fn), hash|
          hash[key] = lambda_fn.call(params)
        end.compact_blank
      end
    end
  end
end
