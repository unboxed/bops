# frozen_string_literal: true

module BopsAdmin
  class ConditionsController < PolicyController
    before_action :set_conditions, only: %i[index]
    before_action :build_condition, only: %i[new create]
    before_action :set_condition, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to conditions_path
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
        if @condition.save
          format.html do
            redirect_to conditions_path, notice: t(".condition_successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @condition.update(condition_params)
          format.html do
            redirect_to conditions_path, notice: t(".condition_successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @condition.destroy
          format.html do
            redirect_to conditions_path, notice: t(".condition_successfully_destroyed")
          end
        else
          format.html do
            redirect_to conditions_path, alert: t(".condition_unsuccessfully_destroyed")
          end
        end
      end
    end

    private

    def set_conditions
      @pagy, @conditions = pagy(current_local_authority.conditions.all_conditions(search_param), limit: 10)
    end

    def search_param
      params.fetch(:q, "")
    end

    def build_condition
      @condition = current_local_authority.conditions.build(condition_params)
    end

    def set_condition
      @condition = current_local_authority.conditions.find(params[:id])
    end

    def condition_params
      if action_name == "new"
        {}
      else
        params.require(:condition).permit(*condition_attributes)
      end
    end

    def condition_attributes
      %i[title text reason]
    end
  end
end
