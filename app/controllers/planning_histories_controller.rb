# frozen_string_literal: true

class PlanningHistoriesController < AuthenticationController
  before_action :set_planning_application

  def show
    @planning_history = Apis::Paapi::Query.new.fetch(@planning_application.uprn)

    respond_to do |format|
      format.html
    end
  end
end
