# frozen_string_literal: true

module BopsApi
  module V2
    class PingController < ApplicationController
      def index
        respond_to do |format|
          format.json
        end
      end
    end
  end
end
