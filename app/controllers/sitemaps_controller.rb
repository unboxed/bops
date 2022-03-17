# frozen_string_literal: true

class SitemapsController < AuthenticationController
  before_action :set_planning_application

  def show
    respond_to do |format|
      format.html
    end
  end

  def update
    new_map = @planning_application.boundary_geojson.blank?
    @planning_application.boundary_geojson = params[:planning_application][:boundary_geojson]
    @planning_application.boundary_created_by = current_user
    @planning_application.save!

    if new_map
      @planning_application.audit_boundary_geojson!("created")
    else
      @planning_application.audit_boundary_geojson!("updated")
    end

    redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: "Site boundary has been updated"
  end
end
