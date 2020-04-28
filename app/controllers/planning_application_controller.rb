# frozen_string_literal: true

class PlanningApplicationController < ApplicationController
  def show
    @planning_application = PlanningApplication.find(params[:id])
  end
end
