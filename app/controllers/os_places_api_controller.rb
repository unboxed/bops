# frozen_string_literal: true

class OsPlacesApiController < ApplicationController
  def index
    response = Apis::OsPlaces::Query.new.find_addresses(params[:query])

    respond_to do |format|
      format.json { render json: response.body }
    end
  end

  def search_addresses_by_polygon
    geojson = JSON.parse(request.body.read)["geojson"]

    response = Apis::OsPlaces::Query.new.find_addresses_by_polygon(geojson)

    respond_to do |format|
      format.json { render json: response }
    end
  end
end
