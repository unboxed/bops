# frozen_string_literal: true

class DocumentsController < AuthenticationController
  include ActiveStorage::SetCurrent

  before_action :set_planning_application
  before_action :set_document, except: %i[index
                                          new
                                          confirm_new
                                          create
                                          edit
                                          update]
  before_action :disable_flash_header, only: :index

  def index
    @documents = policy_scope(@planning_application.documents).order(:created_at)
    @planning_application.documents_validated_at ||= @planning_application.created_at
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
    @document_form = DocumentWizard::UploadForm.new
  end

  def create
    @document_form = DocumentWizard::ConfirmUploadForm.new(
      document_upload_confirmation_params,
    )

    if !@document_form.valid?
      @blob = ActiveStorage::Blob.find_signed(@document_form.file)
      render :confirm_new
    elsif !@document_form.confirmed?
      @document_form = DocumentWizard::UploadForm.new(document_upload_params)
      render :new
    else
      document = @planning_application.documents.build(document_upload_params)

      if document.save
        flash[:notice] = "#{document.file.filename} has been uploaded."
        redirect_to planning_application_documents_path
      else
        @document_form = DocumentWizard::UploadForm.new(document_upload_params)
        @document_form.validate
        @document_form.errors.merge!(document.errors)
        render :new
      end
    end
  end

  def confirm
    assign_archive_reason_to_form
  end

  def confirm_new
    @document_form = DocumentWizard::UploadForm.new(document_upload_params)

    if @document_form.valid?
      # progress to the confirmation step
      @blob = ActiveStorage::Blob.find_signed(@document_form.file)
    else
      render :new
    end
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
    document_params[:tags].reject! {|tag| tag.blank? }
    document_params
  end

  def document_upload_params
    params.fetch(:document_form, {}).permit(:file, tags: [])
  end

  def document_upload_confirmation_params
    document_upload_params.merge(
      params.fetch(:document_form, {}).permit(:confirmation),
    )
  end

  def document_form_params
    params.permit document_form: %i[document_id archive_reason updated_at]
  end

  def form_params
    params.permit confirmation: [:confirm]
  end

  def set_planning_application
    @planning_application = authorize(PlanningApplication.find(
                                        params[:planning_application_id],
                                      ))
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
