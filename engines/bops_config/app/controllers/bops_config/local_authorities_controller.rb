# frozen_string_literal: true

module BopsConfig
  class LocalAuthoritiesController < ApplicationController
    def index
      @local_authorities = LocalAuthority.all.order(short_name: :asc)
      respond_to do |format|
        format.html
      end
    end

    def show
      @local_authority = LocalAuthority.find(params[:id])
      respond_to do |format|
        format.html
      end
    end
  end
end
