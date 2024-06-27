# frozen_string_literal: true

module BopsAdmin
  class PolicyGuidancesController < ApplicationController
    before_action :set_policy_guidances, only: %i[index]
    before_action :build_policy_guidance, only: %i[new create]
    before_action :set_policy_guidance, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to policy_guidances_path
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
        if @policy_guidance.save
          format.html do
            redirect_to policy_guidances_path, notice: t(".successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @policy_guidance.update(policy_guidance_params)
          format.html do
            redirect_to policy_guidances_path, notice: t(".successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @policy_guidance.destroy
          format.html do
            redirect_to policy_guidances_path, notice: t(".successfully_destroyed")
          end
        else
          format.html do
            redirect_to policy_guidances_path, alert: t(".not_destroyed")
          end
        end
      end
    end

    private

    def set_policy_guidances
      @pagy, @policy_guidances = pagy(current_local_authority.policy_guidances.search(search_param), items: 10)
    end

    def search_param
      params.fetch(:q, "")
    end

    def build_policy_guidance
      @policy_guidance = current_local_authority.policy_guidances.build(policy_guidance_params)
    end

    def set_policy_guidance
      @policy_guidance = current_local_authority.policy_guidances.find(params[:id])
    end

    def policy_guidance_params
      if action_name == "new"
        {}
      else
        params.require(:policy_guidance).permit(*policy_guidance_attributes, policy_area_ids: [])
      end
    end

    def policy_guidance_attributes
      %i[code description url]
    end
  end
end
