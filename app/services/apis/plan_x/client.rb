# frozen_string_literal: true

require "faraday"
require "rgeo/geo_json"
require "uri"

module Apis
  module PlanX
    class Client
      HOST = "https://api.editor.planx.uk"
      TIMEOUT = 5

      def call(wkt: nil, geojson: nil)
        if wkt.nil?
          raise ArgumentError, "Must provide either `wkt` or `geojson`" if geojson.nil?

          wkt = geojson_to_wkt(geojson)
        end

        faraday.get("/gis/opensystemslab?geom=#{URI.encode_uri_component wkt}&analytics=false") do |request|
          request.options[:timeout] = TIMEOUT
        end
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
        else
          geom.as_text # it's just a single feature
        end
      end
    end
  end
end
