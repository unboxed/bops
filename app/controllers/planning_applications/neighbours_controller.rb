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
    end

    def update
    end

    def destroy
    end

    private

    def neighbour_id
      Integer(params[:id].to_s)
    end

    def set_neighbour
    end

    def neighbour_params
      params.require(:neighbour).permit(:address)
    end
  end
end
