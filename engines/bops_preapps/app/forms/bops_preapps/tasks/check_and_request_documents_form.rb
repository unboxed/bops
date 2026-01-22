# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckAndRequestDocumentsForm < Form
      self.task_actions = %w[save_and_complete edit_form]

      def update(params)
        transaction do
          super do
            if action.in?(task_actions)
              send(action.to_sym)
            else
              raise ArgumentError, "Invalid task action: #{action.inspect}"
            end
          end
        end
      end

      def flash(type, controller)
        case type
        when :notice
          controller.t(".#{slug}.success")
        when :alert
          controller.t(".#{slug}.failure")
        end
      end

      private

      def save_and_complete
        planning_application.update!(documents_missing: additional_request_pending?)
        super
      end

      def additional_request_pending?
        planning_application.additional_document_validation_requests.pre_validation.open_or_pending.any?
      end
    end
  end
end
