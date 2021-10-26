# frozen_string_literal: true

module ValidationRequests
  extend ActiveSupport::Concern

  included do
    before_action :set_planning_application
    before_action :set_validation_request

    rescue_from ValidationRequest::RecordCancelError do |_exception|
      redirect_failed_cancel_request
    end

    def destroy
      request_type_instance.destroy

      respond_to do |format|
        if request_type_instance.destroyed?
          format.html do
            redirect_to planning_application_validation_requests_path(@planning_application),
                        notice: "Validation request was successfully deleted."
          end
        else
          format.html do
            redirect_to planning_application_validation_requests_path(@planning_application),
                        alert: "Couldn't delete validation request - please contact support."
          end
        end
      end
    end

    def cancel_confirmation
      respond_to do |format|
        if request_type_instance.may_cancel?
          format.html { render :cancel_confirmation }
        else
          format.html { render plain: "Not Found", status: :not_found }
        end
      end
    end

    def cancel
      respond_to do |format|
        if request_type_instance.may_cancel?
          request_type_instance.assign_attributes(cancel_validation_request_params)
          request_type_instance.cancel_request!

          send_cancelled_validation_request_mail if @planning_application.invalidated?

          format.html do
            redirect_to planning_application_validation_requests_path(@planning_application),
                        notice: "Validation request was successfuly cancelled."
          end
        else
          format.html { redirect_failed_cancel_request }
        end
      end
    end

    private

    def redirect_failed_cancel_request
      redirect_to send("cancel_confirmation_planning_application_#{request_type}_path",
                       @planning_application, request_type_instance),
                  alert: "Error cancelling validation request - please contact support."
    end

    def cancel_validation_request_params
      params.require(request_type.to_sym).permit(:cancel_reason)
    end

    def request_type_instance
      instance_variable_get("@#{request_type}")
    end

    def request_type
      @request_type ||= request_klass_name.underscore
    end

    def request_klass
      @request_klass ||= request_klass_name.constantize
    end

    def request_klass_name
      controller_name.classify
    end

    def set_validation_request
      return unless params[:id]

      instance_variable_set("@#{request_type}", @planning_application.send(request_type.pluralize).find(params[:id]))
    end

    def send_cancelled_validation_request_mail
      unless request_type_instance.cancelled?
        raise ValidationRequest::CancelledEmailError,
              "Validation request: #{request_klass_name}, ID: #{request_type_instance.id} must have a cancelled state."
      end

      PlanningApplicationMailer.cancelled_validation_request_mail(
        @planning_application,
        request_type_instance
      ).deliver_now
    end
  end
end
