# frozen_string_literal: true

module BopsPreapps
  module ValidationRequests
    class CancellationsController < AuthenticationController
      before_action :set_layout
      before_action :set_planning_application
      before_action :set_case_record
      before_action :set_validation_request

      before_action :ensure_request_is_cancelable

      helper_method :task_redirect_path

      def new
        respond_to do |format|
          format.html
        end
      end

      def create
        @validation_request.assign_attributes(validation_request_params)
        @validation_request.cancel_request!

        if @planning_application.validation_complete?
          @validation_request.send_cancelled_validation_request_mail
        end

        respond_to do |format|
          format.html do
            redirect_to task_redirect_path, notice: t(".#{@validation_request.type_param}")
          end
        end
      rescue ValidationRequest::RecordCancelError
        respond_to do |format|
          format.html { render :new }
        end
      end

      private

      def set_layout
        @show_header_bar = true
        @show_sidebar = true
      end

      def set_planning_application
        scope = current_local_authority.planning_applications
        planning_application = scope.find_by!(reference: params[:reference])

        @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
      end

      def set_case_record
        @case_record = @planning_application.case_record
      end

      def set_validation_request
        @validation_request = @planning_application.validation_requests.find(params[:validation_request_id])
      end

      def validation_request_params
        params.require(:validation_request).permit(:cancel_reason)
      end

      def task_redirect_lookup(scope)
        scope = "bops_preapps.validation_requests.#{scope}"
        t(@validation_request.type_symbol, scope: scope.to_sym)
      end

      def task_redirect_slug
        task_redirect_lookup("redirect_slugs")
      end

      def task_redirect_path
        task_path(@planning_application, task_redirect_slug)
      end

      def ensure_request_is_cancelable
        unless @validation_request.open_or_pending? && @planning_application.validation_complete?
          redirect_to task_redirect_path, alert: t(".validation_request_not_cancelable")
        end
      end
    end
  end
end
