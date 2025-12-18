# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SendValidationDecisionForm < Form
      self.task_actions = %w[save_and_complete save_and_invalidate]

      validate on: :save_and_invalidate do
        unless planning_application.may_invalidate?
          errors.add :base, :invalid, message: "This planning application cannot be marked as invalid"
        end
      end

      after_update do
        if planning_application.invalid?
          planning_application.send_invalidation_notice_mail
        else
          planning_application.send_validation_notice_mail
        end
      end

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
          planning_application.invalidate!
          task.complete!
        end
      end

      def save_and_complete
        transaction do
          planning_application.update!(validated_at: planning_application.valid_from_date)
          planning_application.start!
          task.complete!
        end
      end
    end
  end
end
