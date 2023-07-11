# frozen_string_literal: true

require "faraday"
require "rgeo/geo_json"
require "uri"

module Apis
  module PlanX
    module Query
      HOST = "https://api.editor.planx.uk"
      TIMEOUT = 5

      def self.query(**args)
        request(**args) => {response:, **query_details}

        if response&.success?
          JSON.parse(response.body, symbolize_names: true).merge(query_details)
        else
          {}
        end
      rescue Faraday::ResourceNotFound, Faraday::ClientError
        {}
      rescue Faraday::Error => e
        Appsignal.send_exception(e)
        {}
      end

      def self.request(wkt: nil, geojson: nil)
        if wkt.blank?
          raise ArgumentError, "Must provide either `wkt` or `geojson`" if geojson.blank?

          wkt = geojson_to_wkt(geojson)
        end

        return { response: nil } if wkt.blank?

        faraday = Faraday.new(url: HOST) { |f| f.response :raise_error }
        request_url = "/gis/opensystemslab?geom=#{URI.encode_uri_component wkt}&analytics=false"
        response = faraday.get(request_url) do |request|
          request.options[:timeout] = TIMEOUT
        end

        { response:, wkt:, geojson:, planx_url: "#{HOST}#{request_url}" }
      end

      def self.geojson_to_wkt(geojson)
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
