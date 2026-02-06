# frozen_string_literal: true

module BopsCore
  module Tasks
    module CheckAndRequestDocumentsForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_and_complete edit_form]

        class_attribute :reference_param_name, default: :reference
      end

      def update(params)
        transaction do
          super do
            case action
            when "save_and_complete"
              save_and_complete
            when "edit_form"
              edit_form
            else
              raise ArgumentError, "Invalid task action: #{action.inspect}"
            end
          end
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
