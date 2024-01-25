# frozen_string_literal: true

module BopsApi
  class CreateNeighbourBoundaryGeojsonJob < ApplicationJob
    queue_as :low_priority
    discard_on ActiveJob::DeserializationError

    def perform(planning_application)
      response = ::Apis::OsPlaces::Query.new.find_addresses_by_radius(planning_application.latitude, planning_application.longitude).to_json

      latlons = JSON.parse(JSON.parse(response)["body"])["results"].map do |result|
        [result["DPA"]["LNG"], result["DPA"]["LAT"]]
      end
      
      feature = latlons.map do |coordinates|
        {
          type: "Feature",
          geometry: {
            coordinates: [
              coordinates.first,
              coordinates.second
            ],
            type: "Point"
          }
        }
      end

      feature.push(planning_application.boundary_geojson)

      planning_application.update(neighbour_boundary_geojson:
        {
          type: "FeatureCollection",
          features: blah
        }
      )
    end
  end
end
