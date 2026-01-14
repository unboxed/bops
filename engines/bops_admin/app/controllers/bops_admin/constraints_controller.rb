# frozen_string_literal: true

module BopsAdmin
  class ConstraintsController < PolicyController
    before_action :set_constraints, only: %i[index]
    before_action :build_constraint, only: %i[new create]
    before_action :set_constraint, only: %i[edit update destroy]

    rescue_from Pagy::OverflowError do
      redirect_to constraints_path
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
        if @constraint.save
          format.html do
            redirect_to constraints_path, notice: t(".successfully_created")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @constraint.update(constraint_params)
          format.html do
            redirect_to constraints_path, notice: t(".successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @constraint.destroy
          format.html do
            redirect_to constraints_path, notice: t(".successfully_destroyed")
          end
        else
          format.html do
            redirect_to constraints_path, alert: t(".not_destroyed")
          end
        end
      end
    end

    private

    def set_constraints
      @pagy, @constraints = pagy(current_local_authority.constraints, limit: 10)
    end

    def build_constraint
      @constraint = current_local_authority.constraints.build({
        category: constraint_params[:category]&.downcase&.tr(" ", "_"),
        type: constraint_params[:type]&.downcase&.tr(" ", "_")
      })
    end

    def set_constraint
      @constraint = current_local_authority.constraints.find(params[:id])
    end

    def constraint_params
      if action_name == "new"
        {}
      else
        params.require(:constraint).permit(*constraint_attributes)
      end
    end

    def constraint_attributes
      %i[type category]
    end
  end
end
