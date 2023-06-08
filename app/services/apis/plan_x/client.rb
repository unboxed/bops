# frozen_string_literal: true

require "faraday"
require "rgeo/geo_json"
require "uri"

module Apis
  module PlanX
    class Client
      # https://api.editor.planx.uk/gis/opensystemslab?geom=POLYGON+%28%28-0.07629275321961124+51.48596289289142%2C+-0.0763061642646857+51.48591028066045%2C+-0.07555112242699404+51.48584764697301%2C+-0.07554173469544191+51.48590192950712%2C+-0.07629275321961124+51.48596289289142%29%29&analytics=false
      HOST = "https://api.editor.planx.uk"
      TIMEOUT = 5

      def call(wkt: nil, geojson: nil)
        if wkt.blank?
          raise ArgumentError, "Must provide either `wkt` or `geojson`" if geojson.blank?

          wkt = geojson_to_wkt(geojson)
        end

        return { response: nil } if wkt.blank?

        request_url = "/gis/opensystemslab?geom=#{URI.encode_uri_component wkt}&analytics=false"
        response = faraday.get(request_url) do |request|
          request.options[:timeout] = TIMEOUT
        end

        { response:, wkt:, geojson:, planx_url: "#{HOST}#{request_url}" }
      end

      private

      def faraday
        @faraday ||= Faraday.new(url: HOST) do |f|
          f.response :raise_error
        end
      end

      def geojson_to_wkt(geojson)
        geom = RGeo::GeoJSON.decode(geojson)
        if geom.respond_to? :entries
          # it's a collection, which rgeo doesn't convert directly

          # the map seems to sometimes return a collection of one element so
          # we need to handle this, but we're not likely to get more than one
          # element for our usecase.
          entries = geom.entries.filter_map(&:geometry).map(&:as_text)
          "GEOMETRYCOLLECTION (#{entries.join(', ')})"
        elsif geom.respond_to? :geometry
          geom.geometry.as_text
        elsif geom.respond_to? :as_text
          geom.as_text
        end
      end
    end
  end
end
