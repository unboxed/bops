# frozen_string_literal: true

class DocumentsController < AuthenticationController
  include ActiveStorage::SetCurrent

  before_action :set_planning_application
  before_action :set_document, except: %i[index
                                          new
                                          create
                                          edit
                                          update]
  before_action :disable_flash_header, only: :index

  def index
    @documents = @planning_application.documents.order(:created_at)
  end

  def edit
    @document = @planning_application.documents.find(params[:id])
  end

  def update
    @document = @planning_application.documents.find(params[:id])
    if @document.update(document_params)
      flash[:notice] = "Document has been updated"
      redirect_to action: :index
    else
      render :edit
    end
  end

  def archive
    assign_archive_reason_to_form
  end

  def new
    @document = @planning_application.documents.build
  end

  def create
    @document = @planning_application.documents.build(tags: document_params[:tags], file: document_params[:file])

    if @document.save
      flash[:notice] = "#{@document.file.filename} has been uploaded."
      audit("uploaded", @document.file.filename)
      redirect_to planning_application_documents_path
    else
      render :new
    end
  end

  def confirm
    assign_archive_reason_to_form
  end

  def validate_archive_reason
    if @document_form.archive_reason
      render :confirm
    else
      @document_form.validate
      render :archive
    end
  end

  def confirm_archived
    @document.archive(params[:archive_reason])
    audit("archived", @document.file.filename)
    flash[:notice] = "#{@document.name} has been archived"
    redirect_to planning_application_documents_path
  end

  def verify_selection
    reason = params["archive_reason"]
    if form_params[:confirmation]
      validate_confirmation
    else
      @document_form.validate
      @document_form.archive_reason = reason
      render :confirm
    end
  end

  def validate_confirmation
    case form_params[:confirmation][:confirm]
    when "yes"
      confirm_archived
    when "no"
      render :archive
    end
  end

  def validate_step
    assign_archive_reason_to_form
    case params[:current_step]
    when "confirm"
      verify_selection
    when "archive"
      validate_archive_reason
    end
  end

private

  def documents_list_params
    params.require(:documents_list).permit(documents: %i[id numbers])
  end

  def document_params
    document_params = params.fetch(:document, {}).permit(:archive_reason, :name, :archived_at, :numbers, :file, tags: [])
    document_params[:tags].reject!(&:blank?)
    document_params
  end

  def document_upload_params
    params.fetch(:document, {}).permit(:file, tags: [])
  end

  def document_form_params
    params.permit document_form: %i[document_id archive_reason updated_at]
  end

  def form_params
    params.permit confirmation: [:confirm]
  end

  def set_planning_application
    @planning_application = current_local_authority.planning_applications.find(params[:planning_application_id])
  end

  def set_document
    @document = @planning_application.documents.find(
      params[:document_id],
    )
  end

  def assign_archive_reason_to_form
    archive_reason = document_form_params[:document_form]
    @document_form = DocumentWizard::ArchiveForm.new(archive_reason)
  end
end
