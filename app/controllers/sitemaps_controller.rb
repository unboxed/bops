# frozen_string_literal: true

class SitemapsController < AuthenticationController
  before_action :set_planning_application

  def show
    respond_to do |format|
      format.html
    end
  end

  def validate
    @planning_application.update(red_line_boundary_params)

    respond_to do |format|
      format.html do
        if @planning_application.valid_red_line_boundary?
          redirect_to planning_application_validation_tasks_path(@planning_application),
                      notice: "Red line boundary was marked as valid."
        elsif @planning_application.valid_red_line_boundary.nil?
          flash.now[:error] = "You must first select Valid or Invalid to continue."
          render :show
        else
          redirect_to new_planning_application_red_line_boundary_change_validation_request_path
        end
      end
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

  private

  def red_line_boundary_params
    if params[:planning_application]
      params.require(:planning_application).permit(:valid_red_line_boundary)
    else
      params.permit(:valid_red_line_boundary)
    end
  end
end
