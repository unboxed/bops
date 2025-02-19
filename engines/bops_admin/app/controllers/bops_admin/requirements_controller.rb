# frozen_string_literal: true

module BopsAdmin
  class RequirementsController < ApplicationController
    before_action :set_requirements, only: %i[index]
    before_action :build_requirement, only: %i[new create]
    before_action :set_requirement, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to requirements_path
    end

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

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @requirement.save
          format.html do
            redirect_to requirements_path, notice: t(".successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @requirement.update(requirement_params)
          format.html do
            redirect_to requirements_path, notice: t(".successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @requirement.destroy
          format.html do
            redirect_to requirements_path, notice: t(".successfully_destroyed")
          end
        else
          format.html do
            redirect_to requirements_path, alert: t(".not_destroyed")
          end
        end
      end
    end

    private

    def set_requirements
      @pagy, @requirements = pagy(current_local_authority.requirements.search(search_param), limit: 10)
    end

    def search_param
      params.fetch(:q, "")
    end

    def build_requirement
      @requirement = current_local_authority.requirements.build(requirement_params)
    end

    def set_requirement
      @requirement = current_local_authority.requirements.find(params[:id])
    end

    def requirement_params
      if action_name == "new"
        {}
      else
        params.require(:requirement).permit(*requirement_attributes, policy_area_ids: [])
      end
    end

    def requirement_attributes
      %i[category description guidelines url]
    end
  end
end
