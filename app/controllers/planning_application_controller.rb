# frozen_string_literal: true

class PlanningApplicationController < ApplicationController
  def show
    @planning_application = PlanningApplication.find(params[:id])
    @site = @planning_application.site
    @agent = @planning_application.agent if @planning_application.agent
    @applicant = @planning_application.applicant
  end
end
