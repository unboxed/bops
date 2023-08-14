# frozen_string_literal: true

class OsPlacesApiController < ApplicationController
  protect_from_forgery except: :search_addresses_by_radius

  def index
    response = Apis::OsPlaces::Query.new.find_addresses(params[:query])

    respond_to do |format|
      format.js { render json: response.body }
    end
  end

  def search_addresses_by_polygon
    data = JSON.parse(request.body.read)
    geojson = data["geojson"]

    response = Apis::OsPlaces::Query.new.find_addresses_by_polygon(geojson)

    respond_to do |format|
      format.js { render json: response }
    end
  end

  def search_addresses_by_radius
    response = Apis::OsPlaces::Query.new.find_addresses_by_radius(params[:point], params[:radius])

    respond_to do |format|
      format.js { render json: response }
    end
  end
end
