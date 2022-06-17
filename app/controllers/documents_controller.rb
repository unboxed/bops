# frozen_string_literal: true

class DocumentsController < AuthenticationController
  include ActiveStorage::SetCurrent

  before_action :set_planning_application
  before_action :set_document, only: %i[edit update archive confirm_archive unarchive]
  before_action :disable_flash_header, only: :index
  before_action :ensure_document_edits_unlocked, only: %i[new edit update archive unarchive]
  before_action :ensure_blob_is_representable, only: %i[edit update archive unarchive]
  before_action :validate_document?, only: %i[edit update]

  def index
    @documents = @planning_application.documents

    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html { render :edit }
    end
  end

  def update
    respond_to do |format|
      format.html do
        if @document.update(document_params)
          if validate_document? && @document.validated == false
            redirect_to new_planning_application_replacement_document_validation_request_path(document: @document)
          else
            redirect_to redirect_url, notice: "Document has been updated"
          end
        else
          render :edit
        end
      end
    end
  end

  def archive
    respond_to do |format|
      format.html
    end
  end

  def unarchive
    @document.unarchive!

    if @document.unarchived?
      flash[:notice] = "#{@document.name} has been restored"
    else
      flash[:alert] = "There was an error with unarchiving #{@document.name}"
    end

    redirect_to action: :index
  end

  def new
    @document = @planning_application.documents.build
  end

  def create
    @document = @planning_application.documents.build(document_params)

    if @document.save
      flash[:notice] = "#{@document.file.filename} has been uploaded."
      redirect_to planning_application_documents_path
    else
      render :new
    end
  end

  def confirm_archive
    @document.archive(document_params[:archive_reason])

    if @document.archived?
      flash[:notice] = "#{@document.name} has been archived"
      redirect_to planning_application_documents_path
    else
      flash[:alert] = "There was an error with archiving #{@document.name}"
      render :archive
    end
  rescue Document::NotArchiveableError => e
    flash[:alert] = e
    render :archive
  end

  private

  def document_params
    document_params = params.fetch(:document, {}).permit(:archive_reason, :name, :archived_at,
                                                         :numbers, :publishable, :referenced_in_decision_notice,
                                                         :validated, :invalidated_document_reason, :file,
                                                         :received_at, :created_by, tags: [])
    document_params[:tags]&.reject!(&:blank?)
    document_params
  end

  def set_document
    @document = @planning_application.documents.find(document_id)
  end

  def document_id
    Integer(params[:document_id] || params[:id])
  end

  def ensure_document_edits_unlocked
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
  end

  def validate_document?
    @validate_document ||= params[:validate] == "yes"
  end

  def redirect_url
    if @validate_document
      planning_application_validation_tasks_path(@planning_application)
    else
      planning_application_documents_path(@planning_application)
    end
  end

  def ensure_blob_is_representable
    render plain: "forbidden", status: :forbidden and return unless @document.representable?
  end
end
