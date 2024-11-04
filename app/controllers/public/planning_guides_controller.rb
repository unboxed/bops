# frozen_string_literal: true

module Public
  class PlanningGuidesController < ApplicationController
    before_action :set_planning_guide, only: :show
    before_action :raise_routing_error, only: :show, unless: :planning_guide_exists?

    def index
      respond_to do |format|
        format.html
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def set_planning_guide
      @planning_guide = "public/planning_guides/#{params[:path]}"
    end

    def planning_guide_exists?
      template_exists?(@planning_guide)
    end

    def raise_routing_error
      raise ActionController::RoutingError, "Couldn't find planning guide #{params[:path]}"
    end
  end
end
