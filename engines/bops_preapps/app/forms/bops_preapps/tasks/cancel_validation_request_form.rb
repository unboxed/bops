# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CancelValidationRequestForm < Form
      self.task_actions = %w[cancel]

      attribute :cancel_reason, :string
      attribute :validation_request_id, :integer

      with_options on: :cancel do
        validates :cancel_reason, presence: {message: "Explain to the applicant why this request is being cancelled"}
      end

      def validation_request
        @validation_request ||= planning_application.validation_requests.find(validation_request_id)
      end

      def url(options = {})
        route_for(:cancel_request, planning_application, options.with_defaults(task_slug: task.full_slug, only_path: true))
      end

      def redirect_url(options = {})
        route_for(:task, planning_application, task, options.with_defaults(only_path: true))
      end

      def flash(type, controller)
        case type
        when :notice
          return nil unless after_success == "redirect"

          controller.t(".#{slug}.cancel_request")
        when :alert
          controller.t(".#{slug}.failure")
        end
      end

      def update(params)
        super do
          cancel_validation_request
        end
      end

      private

      def cancel_validation_request
        transaction do
          validation_request.assign_attributes(cancel_reason:)
          validation_request.cancel_request!
          validation_request.send_cancelled_validation_request_mail unless planning_application.not_started?
          task.not_started!
        end
      end

      def form_params(params)
        params.fetch(param_key, {}).permit(:cancel_reason, :validation_request_id)
      end
    end
  end
end
