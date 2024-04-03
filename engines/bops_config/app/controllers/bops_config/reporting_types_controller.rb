# frozen_string_literal: true

module BopsConfig
  class ReportingTypesController < ApplicationController
    before_action :build_reporting_type, only: %i[new create]
    before_action :set_reporting_types, only: %i[index]
    before_action :set_reporting_type, only: %i[edit update]

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      respond_to do |format|
        format.html
      end
    end

    def create
      @reporting_type.attributes = reporting_type_params

      respond_to do |format|
        if @reporting_type.save
          format.html { redirect_to reporting_types_path, notice: t(".success") }
        else
          format.html { render :new }
        end
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      @reporting_type.attributes = reporting_type_params

      respond_to do |format|
        if @reporting_type.save
          format.html { redirect_to reporting_types_path, notice: t(".success") }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def reporting_type_attributes
      %i[code category description guidance guidance_link legislation]
    end

    def reporting_type_params
      params.require(:reporting_type).permit(*reporting_type_attributes)
    end

    def build_reporting_type
      @reporting_type = ReportingType.new
    end

    def set_reporting_types
      @reporting_types = ReportingType.by_code
    end

    def reporting_type_id
      Integer(params[:id])
    rescue
      raise ActionController::BadRequest, "Invalid reporting type id: #{params[:id].inspect}"
    end

    def set_reporting_type
      @reporting_type = ReportingType.find(reporting_type_id)
    end
  end
end
