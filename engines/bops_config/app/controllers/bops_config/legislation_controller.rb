# frozen_string_literal: true

module BopsConfig
  class LegislationController < ApplicationController
    self.page_key = "legislation"

    before_action :build_legislation, only: %i[new create]
    before_action :set_legislations, only: %i[index]
    before_action :set_legislation, only: %i[edit update destroy]

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
      @legislation.attributes = legislation_params

      respond_to do |format|
        if @legislation.save
          format.html { redirect_to legislation_index_path, notice: t(".success") }
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
      respond_to do |format|
        if @legislation.update(legislation_params.except(:title))
          format.html do
            redirect_to legislation_index_path, notice: t(".success")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        format.html do
          if @legislation.destroy
            redirect_to legislation_index_path, notice: t(".success")
          else
            render :edit
          end
        end
      end
    end

    private

    def set_legislations
      @legislations = Legislation.all
    end

    def set_legislation
      @legislation = Legislation.find(params[:id])
    end

    def build_legislation
      @legislation = Legislation.new
    end

    def legislation_params
      params.require(:legislation).permit(*legislation_attributes)
    end

    def legislation_attributes
      %i[title description link]
    end
  end
end
