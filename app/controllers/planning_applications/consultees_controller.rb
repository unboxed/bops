# frozen_string_literal: true

module PlanningApplications
  class ConsulteesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :set_consultees

    def create
      @consultee = @consultees.new(consultee_params)

      respond_to do |format|
        if @consultee.save
          format.json do
            render json: { consultees: render_consultees }
          end
        else
          format.json { head :unprocessable_content }
        end
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

    def render_consultees
      render_to_string(
        partial: "planning_applications/consultee/emails/consultees",
        locals: { consultees: @consultees },
        formats: :html
      )
    end
  end
end
