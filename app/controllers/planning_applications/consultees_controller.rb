# frozen_string_literal: true

module PlanningApplications
  class ConsulteesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :set_consultees

    def create
      @consultee = @consultees.create!(consultee_params)

      respond_to do |format|
        format.json
      end
    end

    def show
      @consultee = @consultees.find(consultee_id)

      respond_to do |format|
        format.html
      end
    end

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      @constraint = PlanningApplicationConstraint.find(constraint_id)

      respond_to do |format|
        format.html
      end
    end

    private

    def set_consultees
      @consultees = @consultation.consultees
    end

    def constraint_id
      Integer(params[:constraint])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid constraint id: #{params[:constraint].inspect}"
    end

    def consultee_id
      Integer(params[:id])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid consultee id: #{params[:id].inspect}"
    end

    def consultee_params
      params.require(:consultee).permit(*consultee_attributes)
    end

    def consultee_attributes
      %i[origin name email_address role organisation constraint]
    end
  end
end
