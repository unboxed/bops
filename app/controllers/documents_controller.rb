# frozen_string_literal: true

class DocumentsController < AuthenticationController
  include ActiveStorage::SetCurrent

  before_action :set_planning_application
  before_action :set_document, only: %i[archive confirm_archive]
  before_action :disable_flash_header, only: :index
  before_action :ensure_document_edits_unlocked, only: %i[new edit update archive unarchive]

  def index
    @documents = @planning_application.documents.order(:created_at)
  end

  def edit
    @document = @planning_application.documents.find(params[:id])
  end

  def update
    @document = @planning_application.documents.find(params[:id])
    if @document.update(document_params)

      if @document.saved_changes.keys.include?("received_at")
        audit("document_received_at_changed", audit_date_comment(@document), @document.file.filename)
      end
      
      if @document.saved_change_to_attribute?(:validated, from: false, to: true)
        audit("document_changed_to_validated", nil, @document.file.filename)
      elsif @document.saved_change_to_attribute?(:validated, to: false)
        audit("document_invalidated", @document.invalidated_document_reason, @document.file.filename)
      end

      flash[:notice] = "Document has been updated"
      redirect_to action: :index
    else
      render :edit
    end
  end

  def archive
    render :archive
  end

  def unarchive
    @document = @planning_application.documents.find(params[:document_id])
    @document.update!(archived_at: nil)
    audit("unarchived", @document.file.filename)
    flash[:notice] = "#{@document.name} has been restored"

    redirect_to action: :index
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
                                                         :numbers, :publishable, :referenced_in_decision_notice,
                                                         :validated, :invalidated_document_reason, :file,
                                                         :received_at, :created_by, tags: [])
    document_params[:tags]&.reject!(&:blank?)
    document_params
  end

  def set_document
    @document = @planning_application.documents.find(
      params[:document_id]
    )
  end

  def ensure_document_edits_unlocked
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
  end

  def audit_date_comment(document)
    { previous_received_date: document.saved_change_to_received_at.first,
      updated_received_date: document.saved_change_to_received_at.second }.to_json
  end
end
