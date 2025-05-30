# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class AddressParser < BaseParser
      def parse
        {uprn:, address_1:, address_2:, town:, postcode:, longitude:, latitude:}
      end

      private

      def uprn
        params["bs7666UniquePropertyReferenceNumber"].to_s
      end

      def street
        params["bs7666StreetDescription"]
      end

      def number
        params["bs7666Number"]
      end

      def address_1
        [number, street].compact_blank.join(", ")
      end

      def address_2
        params["bs7666Description"]
      end

      def town
        params["bs7666Town"]
      end

      def postcode
        params["bs7666PostCode"]
      end

      # Might need to convert these to EPSG coordinates
      def longitude
        params["bs7666X"]
      end

      def latitude
        params["bs7666Y"]
      end
    end
  end
end
