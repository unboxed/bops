# frozen_string_literal: true

module PlanningApplications
  class NeighboursController < AuthenticationController
    before_action :set_planning_application
    before_action :redirect_to_application_page, unless: :public_or_preapp?

    before_action :set_consultation
    before_action :set_neighbour, only: %i[destroy]

    def destroy
      @neighbour.destroy!

      respond_to do |format|
        format.html do
          redirect_to params[:redirect_to].presence || task_path(@planning_application, "consultees-neighbours-and-publicity/neighbours/add-and-assign-neighbours")
        end
      end
    end

    private

    def neighbour_id
      Integer(params[:id])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid neighbour id: #{params[:id].inspect}"
    end

    def set_neighbour
      @neighbour = @consultation.neighbours.find(neighbour_id)
    end

    def redirect_to_application_page
      redirect_to make_public_planning_application_path(@planning_application), alert: t(".make_public")
    end

    def public_or_preapp?
      @planning_application.make_public? || @planning_application.pre_application?
    end
  end
end
