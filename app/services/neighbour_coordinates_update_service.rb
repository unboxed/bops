# frozen_string_literal: true

module NeighbourCoordinatesUpdateService
  def self.call(neighbour, *args)
    response = Apis::OsPlaces::Query.new.find_addresses(neighbour.address)

    return if response == []

    data = JSON.parse(response.body)

    result = data["results"].first["DPA"]
    long = result["LNG"]
    lat = result["LAT"]

    factory = RGeo::Geographic.spherical_factory(srid: 4326)
    lonlat = factory.point(long, lat)

    neighbour.update!(lonlat:)
  end
end
