# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class AddressParser < BaseParser
        def parse
          {uprn:, address_1:, address_2:, town:, postcode:, longitude:, latitude:}
        end

        private

        def uprn
          params[:uprn]
        end

        def sao
          params.values_at(:sao, :saoEnd).compact_blank.join("–")
        end

        def pao
          params.values_at(:pao, :paoEnd).compact_blank.join("–")
        end

        def street
          params[:street]
        end

        def address_1
          [sao, pao, street].compact_blank.join(", ")
        end

        def address_2
          params[:organisation]
        end

        def town
          params[:town]
        end

        def postcode
          params[:postcode]
        end

        def longitude
          params[:longitude]
        end

        def latitude
          params[:latitude]
        end
      end
    end
  end
end
