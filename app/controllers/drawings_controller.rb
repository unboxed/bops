# frozen_string_literal: true

class DrawingsController < AuthenticationController
  include ActiveStorage::SetCurrent
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application
  before_action :set_drawing, except: [ :index, :new, :confirm_new, :create ]
  before_action :set_planning_application_dashboard_variables
  before_action :disable_flash_header, only: :index

  def index
    @drawings = policy_scope(@planning_application.drawings).order(:created_at)
  end

  def archive
    assign_archive_reason_to_form
  end

  def new
    @drawing_form = DrawingWizard::UploadForm.new
  end

  def create
    @drawing = @planning_application.drawings.build(drawing_upload_params)

    if params[:drawing_form][:confirm_upload] == "true" && @drawing.save
      flash[:notice] = "#{@drawing.plan.filename} has been uploaded."
      redirect_to planning_application_drawings_path
    else
      @drawing_form = DrawingWizard::UploadForm.new(drawing_upload_params)
      @drawing_form.validate
      @drawing_form.errors.merge!(@drawing.errors)
      render :new
    end
  end

  def confirm
    assign_archive_reason_to_form
  end

  def confirm_new
    @drawing_form = DrawingWizard::UploadForm.new(drawing_upload_params)

    if @drawing_form.valid?
      # progress to the confirmation step
      @blob = ActiveStorage::Blob.find_signed(@drawing_form.plan)
    else
      render :new
    end
  end

  def validate_archive_reason
    if @drawing_form.archive_reason
      render :confirm
    else
      @drawing_form.validate
      render :archive
    end
  end

  def confirm_archived
    @drawing.archive(params[:archive_reason])
    flash[:notice] = "#{@drawing.name} has been archived"
    redirect_to planning_application_drawings_path
  end

  def verify_selection
    reason = params["archive_reason"]
    if form_params[:confirmation]
      validate_confirmation
    else
      @drawing_form.validate
      @drawing_form.archive_reason = reason
      render :confirm
    end
  end

  def validate_confirmation
    if form_params[:confirmation][:confirm] == "yes"
      confirm_archived
    elsif form_params[:confirmation][:confirm] == "no"
      render :archive
    end
  end

  def validate_step
    assign_archive_reason_to_form
    if params[:current_step] == "confirm"
      verify_selection
    elsif params[:current_step] == "archive"
      validate_archive_reason
    end
  end

  private

  def drawing_params
    params.fetch(:drawing, {}).permit(:archive_reason, :name, :archived_at)
  end

  def drawing_upload_params
    params.fetch(:drawing_form, {}).permit(:plan, tags: [])
  end

  def drawing_form_params
    params.permit drawing_form: [:drawing_id, :archive_reason, :updated_at]
  end

  def form_params
    params.permit confirmation: [:confirm]
  end

  def set_planning_application
    @planning_application = authorize(PlanningApplication.find(
                                        params[:planning_application_id])
    )
  end

  def set_drawing
    @drawing = @planning_application.drawings.find(
      params[:drawing_id])
  end

  def assign_archive_reason_to_form
    archive_reason = drawing_form_params[:drawing_form]
    @drawing_form = DrawingWizard::ArchiveForm.new(archive_reason)
  end
end
