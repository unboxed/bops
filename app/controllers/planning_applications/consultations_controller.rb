# frozen_string_literal: true

module PlanningApplications
  class ConsultationsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation

    def show
      respond_to do |format|
        format.html
      end
    end

    def update
      @consultation.update!(consultation_params.merge(status: "in_progress"))

      respond_to do |format|
        format.html { redirect_to planning_application_consultation_path(@planning_application) }
      end
    end

    private

    def consultation_params
      params.require(:consultation).permit(:neighbour_letter_text, :resend_existing, :resend_reason)
    end
  end
end
