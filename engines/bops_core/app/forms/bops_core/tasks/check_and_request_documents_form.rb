# frozen_string_literal: true

module BopsCore
  module Tasks
    module CheckAndRequestDocumentsForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_and_complete edit_form]

        class_attribute :reference_param_name, default: :reference
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
