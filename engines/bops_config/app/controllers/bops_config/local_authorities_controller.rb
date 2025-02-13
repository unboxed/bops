# frozen_string_literal: true

module BopsConfig
  class LocalAuthoritiesController < ApplicationController
    before_action :set_local_authorities, only: %i[index]

    def index
      respond_to do |format|
        format.html
      end
    end

    private

    def set_local_authorities
      @local_authorities = LocalAuthority.all.order(short_name: :asc)
    end
  end
end
