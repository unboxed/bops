# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SendValidationDecisionForm < Form
      self.task_actions = %w[save_and_complete save_and_invalidate]

      def update(params)
        super do
          case action
          when "save_and_complete"
            save_and_complete
          when "save_and_invalidate"
            save_and_invalidate
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      private

      def save_and_invalidate
        transaction do
          if planning_application.may_invalidate?
            planning_application.invalidate!
            planning_application.send_invalidation_notice_mail

          else
            validation_requests = planning_application.validation_requests
            @cancelled_validation_requests = validation_requests.where(state: "cancelled")
            @active_validation_requests = validation_requests.where.not(state: "cancelled")
          end
          task.complete!
        end
      end

      def save_and_complete
        transaction do
          planning_application.update(validated_at: planning_application.valid_from_date)
          planning_application.start!
          planning_application.send_validation_notice_mail
          task.complete!
        end
      end
    end
  end
end
