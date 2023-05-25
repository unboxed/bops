# frozen_string_literal: true
require 'faraday'

class OsPlacesApiController < ApplicationController
  def index
    response = Apis::OsPlaces::Query.new.get(params[:query])

    respond_to do |format|
      format.js { render json: JSON.parse(response.body) }
    end
  end
end
