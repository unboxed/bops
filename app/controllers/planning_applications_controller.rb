# frozen_string_literal: true

class PlanningApplicationsController < ApplicationController
  def index
  end

  def show
    @planning_application = PlanningApplication.find(params[:id])
    @site = @planning_application.site
    @agent = @planning_application.agent if @planning_application.agent
    @applicant = @planning_application.applicant
  end
end
