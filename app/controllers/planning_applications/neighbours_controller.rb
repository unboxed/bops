# frozen_string_literal: true

module PlanningApplications
  class NeighboursController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :set_neighbour, only: %i[update destroy]

    def index
      respond_to do |format|
        format.html
      end
    end

    def create
      begin
        @consultation.update!(consultation_params)
        flash[:notice] = t(".success")
      rescue ActiveRecord::RecordInvalid
        flash[:error] = @consultation.errors.full_messages.join("\n")
      end

      respond_to do |format|
        format.html do
          if @consultation.errors.any?
            render :index
          else
            redirect_to planning_application_consultation_neighbour_letters_path(@planning_application)
          end
        end
      end
    end

    def update
      @neighbour.update!(neighbour_params)

      respond_to do |format|
        format.html do
          redirect_to planning_application_consultation_neighbours_path(@planning_application)
        end
      end
    end

    def destroy
      @neighbour.destroy

      respond_to do |format|
        format.html do
          redirect_to planning_application_consultation_neighbours_path(@planning_application)
        end
      end
    end

    private

    def neighbour_id
      Integer(params[:id].to_s)
    end

    def set_neighbour
      @neighbour = @consultation.neighbours.find(neighbour_id)
    end

    def consultation_params
      params.require(:consultation).permit(
        :polygon_geojson,
        neighbours_attributes: %i[id address]
      )
    end

    def neighbour_params
      params.require(:neighbour).permit(:address)
    end
  end
end
