# frozen_string_literal: true

class OsPlacesApiController < ApplicationController
  before_action :set_planning_application, only: :search_addresses_by_polygon

  def index
    response = Apis::OsPlaces::Query.new.find_addresses(params[:query])

    respond_to do |format|
      format.json { render json: response.body }
    end
  end

  def search_addresses_by_polygon
    geojson = JSON.parse(request.body.read)["geojson"]

    response = Apis::OsPlaces::Query.new.find_addresses_by_polygon(geojson, @planning_application.uprn)

    respond_to do |format|
      format.json { render json: response }
    end
  end

  private

  def set_planning_application
    @planning_application = current_local_authority.planning_applications.find_by(id: Integer(params[:planning_application].to_s))
  end
end
