# frozen_string_literal: true

class DocumentsController < AuthenticationController
  include ActiveStorage::SetCurrent

  before_action :set_planning_application
  before_action :set_document, only: %i[edit update archive confirm_archive unarchive]
  before_action :ensure_document_edits_unlocked, only: %i[new edit update archive unarchive]
  before_action :validate_document?, only: %i[edit update]
  before_action :replacement_document_validation_request, only: %i[edit update]
  before_action :set_return_to_session, only: %i[update]
  before_action :show_sidebar, only: %i[edit update archive]

  def index
    @documents = @planning_application.documents.default.with_file_attachment
    @additional_document_validation_requests = @planning_application
      .additional_document_validation_requests
      .post_validation
      .open_or_pending

    respond_to do |format|
      format.html
    end
  end

  def new
    @document = @planning_application.documents.build
  end

  def edit
    set_return_to_session

    respond_to do |format|
      format.html { render :edit }
    end
  end

  def create
    @document = @planning_application.documents.build(document_params)

    if @document.save
      flash[:notice] = "#{@document.name} has been uploaded."
      redirect_to planning_application_documents_path
    else
      render :new
    end
  end

  def update
    respond_to do |format|
      format.html do
        if @document.update_or_replace(document_params)
          if validate_document? && @document.validated == false
            redirect_to new_planning_application_validation_validation_request_path(document: @document, type: "replacement_document",
              return_to: params.dig(:document, :redirect_to))
          else
            redirect_to redirect_url, notice: t(".success")
          end
        else
          render :edit
        end
      end
    end
  end

  def archive
    set_return_to_session

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

  def confirm_archive
    @document.archive(document_params[:archive_reason])

    if @document.archived?
      flash[:notice] = "#{@document.name} has been archived"
      redirect_to(params.dig(:document, :redirect_to).presence || return_to_session || planning_application_documents_path(@planning_application))
    else
      flash[:alert] = "There was an error with archiving #{@document.name}"
      render :archive
    end
  rescue Document::NotArchiveableError => e
    flash[:alert] = e.message
    render :archive
  end

  private

  def document_params
    params.require(:document).permit(*document_attributes).merge(tags_param)
  end

  def document_attributes
    %i[
      archive_reason name archived_at numbers
      publishable referenced_in_decision_notice
      available_to_consultees validated
      invalidated_document_reason file
      received_at created_by
    ]
  end

  def tags_param
    {tags: Array.wrap(params.dig(:document, :tags)).compact_blank}
  end

  def set_document
    @document = @planning_application.documents.find(document_id)
  end

  def document_param
    request.path_parameters.key?(:document_id) ? :document_id : :id
  end

  def document_id
    Integer(params[document_param])
  rescue ArgumentError
    raise ActionController::BadRequest, "Invalid document id: #{params[document_param].inspect}"
  end

  def ensure_document_edits_unlocked
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_edit_documents?
  end

  def validate_document?
    @validate_document ||= params[:validate] == "yes"
  end

  def replacement_document_validation_request
    return unless @document.owner.is_a?(ReplacementDocumentValidationRequest)

    @replacement_document_validation_request ||= @document.owner
  end

  def redirect_url
    if params.dig(:document, :redirect_to).present?
      params.dig(:document, :redirect_to)
    elsif @validate_document
      supply_documents_planning_application_path(@planning_application)
    elsif session[:return_to]
      return_to_session
    elsif request.referer&.include?("route=review")
      planning_application_review_documents_path(@planning_application)
    else
      planning_application_documents_path(@planning_application)
    end
  end

  def set_return_to_session
    return unless request.referer&.include?(@planning_application.id.to_s)

    session[:return_to] ||= request.referer
  end

  def return_to_session
    session.delete(:return_to)
  end

  def document_return_to
    params.dig(:document, :redirect_to).presence
  end

  def show_sidebar
    @show_sidebar = if use_new_sidebar_layout?(:validation) &&
        !BLOCKED_SIDEBAR_EMAILS.include?(current_user&.email)
      @planning_application.case_record.tasks.find_by(section: "Validation")
    end
  end
end
