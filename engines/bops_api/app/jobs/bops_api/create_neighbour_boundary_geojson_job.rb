# frozen_string_literal: true

module BopsApi
  class CreateNeighbourBoundaryGeojsonJob < ApplicationJob
    queue_as :low_priority
    discard_on ActiveJob::DeserializationError

    def perform(planning_application)
      response = ::Apis::OsPlaces::Query.new.find_addresses_by_radius(planning_application.lonlat.latitude, planning_application.lonlat.longitude)

      results = JSON.parse(response.body)["results"]

      # API request has no results
      return if results.nil?

      features = create_features(results)

      features.push(planning_application.boundary_geojson) if planning_application.boundary_geojson

      planning_application.update!(neighbour_boundary_geojson:
        {
          type: "FeatureCollection",
          features: features
        })
    rescue JSON::ParserError => exception
      AppSignal.send_error(exception)
    end

    private

    def create_features(results)
      results.map do |result|
        lng, lat = result["DPA"]["LNG"], result["DPA"]["LAT"]
        {
          type: "Feature",
          geometry: {
            coordinates: [lng, lat],
            type: "Point"
          }
        }
      end
    end
  end
end
