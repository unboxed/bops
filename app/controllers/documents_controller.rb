# frozen_string_literal: true

class DocumentsController < AuthenticationController
  include ActiveStorage::SetCurrent

  before_action :set_planning_application
  before_action :set_document, only: %i[archive confirm_archive]
  before_action :disable_flash_header, only: :index
  before_action :ensure_document_edits_unlocked, only: %i[new edit update archive]

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
    render :archive
  end

  def new
    @document = @planning_application.documents.build
  end

  def create
    @document = @planning_application.documents.build(document_params)

    if @document.save
      flash[:notice] = "#{@document.file.filename} has been uploaded."
      audit("uploaded", @document.file.filename)
      redirect_to planning_application_documents_path
    else
      render :new
    end
  end

  def confirm_archive
    @document.archive(document_params[:archive_reason])
    if @document.save
      audit("archived", @document.file.filename)
      flash[:notice] = "#{@document.name} has been archived"
      redirect_to planning_application_documents_path
    end
  end

private

  def document_params
    document_params = params.fetch(:document, {}).permit(:archive_reason, :name, :archived_at,
                                                         :numbers, :publishable, :referenced_in_decision_notice, :file, tags: [])
    document_params[:tags].reject!(&:blank?) if document_params[:tags]
    document_params
  end

  def set_planning_application
    @planning_application = current_local_authority.planning_applications.find(params[:planning_application_id])
  end

  def set_document
    @document = @planning_application.documents.find(
      params[:document_id],
    )
  end

  def ensure_document_edits_unlocked
    render plain: "forbidden", status: 403 and return unless @planning_application.can_validate?
  end
end
