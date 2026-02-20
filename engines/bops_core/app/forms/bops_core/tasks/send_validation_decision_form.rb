# frozen_string_literal: true

module BopsCore
  module Tasks
    module SendValidationDecisionForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_and_complete save_and_invalidate]

        attribute :make_public, :boolean
        delegate :publishable?, to: :planning_application

        validate on: :save_and_invalidate do
          unless planning_application.may_invalidate?
            errors.add :base, :invalid, message: "This planning application cannot be marked as invalid"
          end
        end

        validate on: :save_and_complete, if: :publishable? do
          if make_public.nil?
            errors.add :make_public, :inclusion, message: "Choose whether to publish the application or not"
          end
        end

        after_update if: :publishable? do
          planning_application.update!(make_public:)
        end
      end

      def redirect_url(options = {})
        if task.completed?
          main_app.planning_application_path(planning_application)
        else
          super
        end
      end

      def flash(type, controller)
        case type
        when :notice
          (after_success == "redirect") ? controller.t(".#{slug}.success_html") : nil
        when :alert
          (after_failure == "redirect") ? controller.t(".#{slug}.failure") : nil
        end
      end

      private

      def save_and_invalidate
        transaction do
          planning_application.invalidate!
          planning_application.send_invalidation_notice_mail
          task.complete!
        end
      end

      def save_and_complete
        transaction do
          planning_application.update!(validated_at: planning_application.valid_from_date)
          planning_application.send_validation_notice_mail
          planning_application.start!
          task.complete!
        end
      end
    end
  end
end
