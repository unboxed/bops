# frozen_string_literal: true

module BopsCore
  module CancelsValidationRequests
    extend ActiveSupport::Concern

    included do
      before_action :set_planning_application
      before_action :set_validation_request
      before_action :set_task
      before_action :ensure_request_is_cancelable
      before_action :show_sidebar
      before_action :show_header

      helper_method :cancellation_form_url
      helper_method :back_path
    end

    def new
      respond_to do |format|
        format.html { render template: "bops_core/validation_requests/cancellations/new" }
      end
    end

    def create
      @validation_request.transaction do
        @validation_request.assign_attributes(validation_request_params)
        @validation_request.cancel_request!
        @task.not_started!
      end

      @validation_request.send_cancelled_validation_request_mail if @planning_application.validation_complete?

      respond_to do |format|
        format.html { redirect_to after_cancel_path, notice: t(".#{@task.slug}") }
      end
    rescue ValidationRequest::RecordCancelError
      respond_to do |format|
        format.html { render template: "bops_core/validation_requests/cancellations/new", status: :unprocessable_content }
      end
    end

    private

    def set_validation_request
      @validation_request = @planning_application.validation_requests.find(params[:validation_request_id])
    end

    def validation_request_params
      params.require(:validation_request).permit(:cancel_reason)
    end

    def ensure_request_is_cancelable
      unless @validation_request.open_or_pending? && @planning_application.validation_complete?
        redirect_to after_cancel_path, alert: t(".validation_request_not_cancelable")
      end
    end

    def set_task
      @task = @planning_application.case_record.find_task_by_slug_path!(params[:task_slug])
    end

    def after_cancel_path
      raise NotImplementedError, "Subclasses must implement #after_cancel_path"
    end

    def cancellation_form_url
      raise NotImplementedError, "Subclasses must implement #cancellation_form_url"
    end

    def back_path
      after_cancel_path
    end
  end
end
