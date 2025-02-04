# frozen_string_literal: true

module BopsAdmin
  class CategoriesController < ApplicationController
    before_action :set_categories, only: %i[index]
    before_action :build_category, only: %i[new create]
    before_action :set_category, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to categories_path
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
        if @category.save
          format.html do
            redirect_to categories_path, notice: t(".successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @category.update(category_params)
          format.html do
            redirect_to categories_path, notice: t(".successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @category.destroy
          format.html do
            redirect_to categories_path, notice: t(".successfully_destroyed")
          end
        else
          format.html do
            redirect_to categories_path, alert: t(".not_destroyed")
          end
        end
      end
    end

    private

    def set_categories
      @pagy, @categories = pagy(current_local_authority.categories.search(search_param), limit: 10)
    end

    def search_param
      params.fetch(:q, "")
    end

    def build_category
      @category = current_local_authority.categories.build(category_params)
    end

    def set_category
      @category = current_local_authority.categories.find(params[:id])
    end

    def category_params
      if action_name == "new"
        {}
      else
        params.require(:category).permit(*category_attributes)
      end
    end

    def category_attributes
      %i[description]
    end
  end
end
