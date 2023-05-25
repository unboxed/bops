# frozen_string_literal: true
require 'faraday'

class OsPlacesApiController < ApplicationController
  def index
    Faraday.new("https://api.os.uk/search/places/v1/find?maxresults=20&query=bla&key=#{ENV['OS_VECTOR_TILES_API_KEY']}").get do |request|
      request.options[:timeout] = 5
    end
  end
end
