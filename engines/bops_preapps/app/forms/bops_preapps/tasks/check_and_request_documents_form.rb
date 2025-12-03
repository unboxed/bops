# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckAndRequestDocumentsForm < BaseForm
      def update(params)
        ActiveRecord::Base.transaction do
          planning_application.update!(documents_missing: documents_missing(params))

          if save_draft?
            task.start! || raise(ActiveRecord::RecordInvalid.new(task))
          else
            task.complete! || raise(ActiveRecord::RecordInvalid.new(task))
          end
        end
      rescue ActiveRecord::RecordInvalid
        false
      end

      def permitted_fields(params)
        @button = params[:button]
        params.require(:task).permit(:documents_missing)
      end

      private

      def documents_missing(params)
        missing = params[:documents_missing] == "true"

        missing || additional_request_pending?
      end

      def additional_request_pending?
        planning_application.additional_document_validation_requests.pre_validation.open_or_pending.any?
      end
    end
  end
end
