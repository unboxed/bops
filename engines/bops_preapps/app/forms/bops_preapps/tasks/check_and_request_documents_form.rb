# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckAndRequestDocumentsForm < BaseForm
      def update(params)
        ActiveRecord::Base.transaction do
          case button
          when "edit_form"
            edit_form
          when "save_draft"
            planning_application.update!(documents_missing: documents_missing(params))
            task.start!
          else
            planning_application.update!(documents_missing: documents_missing(params))
            task.complete!
          end
        end
      rescue ActiveRecord::ActiveRecordError
        false
      end

      def permitted_fields(params)
        @button = params[:button]
        params.require(:task).permit(:documents_missing)
      end

      def flash(type, controller)
        return if button == "edit_form"

        case type
        when :notice
          controller.t(".#{slug}.success")
        when :alert
          controller.t(".#{slug}.failure")
        end
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
