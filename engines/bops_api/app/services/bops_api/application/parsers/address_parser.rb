# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class AddressParser
        attr_reader :params

        def initialize(params)
          @params = params
        end

        def parse
          {
            uprn: params[:uprn],
            address_1: "#{params[:pao]}, #{params[:street]}",
            address_2: params[:organisation],
            town: params[:town],
            postcode: params[:postcode],
            lonlat: lonlat(params[:longitude], params[:latitude])
          }
        end

        private

        def lonlat(longitude, latitude)
          return unless longitude.present? && latitude.present?

          "POINT(#{longitude} #{latitude})"
        end
      end
    end
  end
end
