# frozen_string_literal: true

module PlanningApplications
  class RedactNeighbourResponsesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :set_neighbour_response

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      @neighbour_response.redacted_by = current_user

      respond_to do |format|
        if @neighbour_response.update(redact_neighbour_response_params)
          format.html do
            redirect_to neighbour_responses_path, notice: t(".success")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def redact_neighbour_response_params
      params.require(:neighbour_response).permit(
        :response, :redacted_response
      )
    end

    def set_neighbour_response
      @neighbour_response = @consultation.neighbour_responses.find(Integer(params[:id]))
    end

    def neighbour_responses_path
      planning_application_consultation_neighbour_responses_path(@planning_application, @consultation)
    end
  end
end
