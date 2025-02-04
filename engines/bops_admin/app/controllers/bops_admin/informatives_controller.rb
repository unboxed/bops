# frozen_string_literal: true

module BopsAdmin
  class InformativesController < ApplicationController
    before_action :set_informatives, only: %i[index]
    before_action :build_informative, only: %i[new create]
    before_action :set_informative, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to informatives_path
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
        if @informative.save
          format.html do
            redirect_to informatives_path, notice: t(".informative_successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @informative.update(informative_params)
          format.html do
            redirect_to informatives_path, notice: t(".informative_successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @informative.destroy
          format.html do
            redirect_to informatives_path, notice: t(".informative_successfully_destroyed")
          end
        else
          format.html do
            redirect_to informatives_path, alert: t(".informative_unsuccessfully_destroyed")
          end
        end
      end
    end

    private

    def set_informatives
      @pagy, @informatives = pagy(current_local_authority.informatives.all_informatives(search_param), limit: 10)
    end

    def search_param
      params.fetch(:q, "")
    end

    def build_informative
      @informative = current_local_authority.informatives.build(informative_params)
    end

    def set_informative
      @informative = current_local_authority.informatives.find(params[:id])
    end

    def informative_params
      if action_name == "new"
        {}
      else
        params.require(:informative).permit(*informative_attributes)
      end
    end

    def informative_attributes
      %i[title text]
    end
  end
end
