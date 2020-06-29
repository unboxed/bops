# frozen_string_literal: true

class DrawingsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_planning_application_dashboard_variables

  def index
    @drawings = policy_scope(@planning_application.drawings)
  end

  def archive
    @drawing = @planning_application.drawings.find(
        params[:drawing_id])
    assign_archive_reason_to_form
  end

  def confirm
    @drawing = @planning_application.drawings.find(
        params[:drawing_id])
    archive_reason = drawing_form_params[:drawing_form]
    @drawing_form = DrawingWizard::ArchiveForm.new(archive_reason)
  end

  def validate_step
    @drawing = @planning_application.drawings.find(params[:drawing_id])
    assign_archive_reason_to_form
    if !@drawing_form.updated_at.nil? && params[:current_step] == "confirm"
      @drawing.archive(@drawing_form.archive_reason)
      redirect_to planning_application_drawings_path
    elsif @drawing_form.updated_at.nil? && params[:current_step] == "archive"
      render :confirm
    else
      render :archive, notice: "Please select valid reason for archiving"
    end
  end

  private

  def drawing_params
    params.fetch(:drawing, {}).permit(:archive_reason, :name, :archived_at)
  end

  def drawing_form_params
    params.permit drawing_form: [:drawing_id, :archive_reason, :updated_at]
  end

  def set_planning_application
    @planning_application = authorize(PlanningApplication.find(
        params[:planning_application_id])
    )
  end

  def assign_archive_reason_to_form
    archive_reason = drawing_form_params[:drawing_form]
    @drawing_form = DrawingWizard::ArchiveForm.new(archive_reason)
  end
end

