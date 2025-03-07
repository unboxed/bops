# frozen_string_literal: true

module BopsConfig
  class ApplicationTypesController < ApplicationController
    before_action :build_application_type, only: %i[new create]
    before_action :set_application_types, only: %i[index]
    before_action :set_application_type, only: %i[show edit update]

    audit :create, :update,
      unless: -> { @application_type.changed? },
      payload: -> {
        {
          application_type: @application_type.audit_attributes,
          changes: @application_type.audit_changes,
          automated: false
        }
      }

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
      @application_type.attributes = application_type_params

      respond_to do |format|
        if @application_type.save
          format.html { redirect_to next_path, notice: t(".success") }
        else
          format.html { render :new }
        end
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      @application_type.attributes = application_type_params

      respond_to do |format|
        if @application_type.save
          format.html { redirect_to next_path, notice: t(".success") }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def application_type_params
      params.require(:application_type).permit(:code, :suffix)
    end

    def build_application_type
      @application_type = ApplicationType::Config.new
    end

    def next_path
      if @application_type.configured?
        application_type_path(@application_type)
      else
        edit_application_type_category_path(@application_type)
      end
    end

    def set_application_types
      @application_types = ApplicationType::Config.by_name
    end

    def set_application_type
      @application_type = ApplicationType::Config.find(application_type_id)
    end
  end
end
