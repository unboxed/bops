# frozen_string_literal: true

module BopsAdmin
  class PolicyAreasController < ApplicationController
    before_action :set_policy_areas, only: %i[index]
    before_action :build_policy_area, only: %i[new create]
    before_action :set_policy_area, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to policy_areas_path
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
        if @policy_area.save
          format.html do
            redirect_to policy_areas_path, notice: t(".successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @policy_area.update(policy_area_params)
          format.html do
            redirect_to policy_areas_path, notice: t(".successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @policy_area.destroy
          format.html do
            redirect_to policy_areas_path, notice: t(".successfully_destroyed")
          end
        else
          format.html do
            redirect_to policy_areas_path, alert: t(".not_destroyed")
          end
        end
      end
    end

    private

    def set_policy_areas
      @pagy, @policy_areas = pagy(current_local_authority.policy_areas.search(search_param), items: 10)
    end

    def search_param
      params.fetch(:q, "")
    end

    def build_policy_area
      @policy_area = current_local_authority.policy_areas.build(policy_area_params)
    end

    def set_policy_area
      @policy_area = current_local_authority.policy_areas.find(params[:id])
    end

    def policy_area_params
      if action_name == "new"
        {}
      else
        params.require(:policy_area).permit(*policy_area_attributes)
      end
    end

    def policy_area_attributes
      %i[description]
    end
  end
end
