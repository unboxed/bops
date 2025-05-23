# frozen_string_literal: true

module BopsApplicants
  class AddressesController < ApplicationController
    def index
      @addresses = find_addresses

      respond_to do |format|
        format.json { render json: @addresses }
      end
    end

    private

    def find_addresses
      if query.present?
        fetch_addresses
      else
        []
      end
    rescue
      []
    end

    def fetch_addresses
      client = Apis::OsPlaces::Client.new
      response = client.get("find", {query:, output_srs:, maxresults:})
      json = JSON.parse(response.body)
      json.fetch("results", []).map { |r| r.dig("DPA", "ADDRESS") }.compact_blank
    end

    def query
      params[:query].to_s
    end

    def maxresults
      params[:count].to_i.clamp(5, 20)
    end

    def output_srs
      "EPSG:4258"
    end
  end
end
