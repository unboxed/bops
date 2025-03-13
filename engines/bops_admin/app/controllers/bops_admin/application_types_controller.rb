# frozen_string_literal: true

module BopsAdmin
  class ApplicationTypesController < ApplicationController
    before_action :set_application_types, only: %i[index]
    before_action :set_application_type, only: %i[show]

    def index
      respond_to do |format|
        format.html
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def set_application_types
      @application_types = current_local_authority.application_types.by_name
    end

    def set_application_type
      @application_type = current_local_authority.application_types.find(application_type_id)
    end

    def application_type_id
      Integer(params[:id])
    end
  end
end
