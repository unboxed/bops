# frozen_string_literal: true

module PlanningApplications
  class RedactNeighbourResponsesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :set_neighbour_response
    before_action :show_sidebar

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      @neighbour_response.redacted_by = current_user

      respond_to do |format|
        if @neighbour_response.update(redact_neighbour_response_params.except(:response))
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

    def neighbour_response_id
      Integer(params[:id])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid neighbour response id: #{params[:id].inspect}"
    end

    def set_neighbour_response
      @neighbour_response = @consultation.neighbour_responses.find(neighbour_response_id)
    end

    def neighbour_responses_path
      if @planning_application.case_record.find_task_by_slug_path("consultees-neighbours-and-publicity/neighbours/view-neighbour-responses")
        task_path(@planning_application, slug: "consultees-neighbours-and-publicity/neighbours/view-neighbour-responses")
      else
        planning_application_consultation_neighbour_responses_path(@planning_application)
      end
    end

    def show_sidebar
      @show_sidebar = if use_new_sidebar_layout?(@planning_application)
        @planning_application.case_record.tasks.find_by(section: "Consultation")
      end
    end
  end
end
