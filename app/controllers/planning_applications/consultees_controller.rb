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

    private

    def set_consultees
      @consultees = @consultation.consultees
    end

    def consultee_params
      params.require(:consultee).permit(*consultee_attributes)
    end

    def consultee_attributes
      %i[origin name email_address role organisation]
    end
  end
end
