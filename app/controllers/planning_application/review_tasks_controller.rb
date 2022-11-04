# frozen_string_literal: true

class PlanningApplication
  class ReviewTasksController < AuthenticationController
    before_action :set_planning_application

    def index
      respond_to do |format|
        format.html
      end
    end
  end
end
