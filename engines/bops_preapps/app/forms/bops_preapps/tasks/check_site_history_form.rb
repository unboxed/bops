# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckSiteHistoryForm < Form
      self.task_actions = %w[save_and_complete save_draft]
      def update(params)
        super do
          if action.in?(task_actions)
            send(action.to_sym)
          else
            raise ArgumentError, "Invalid task action: #{action.inspect}"
          end
        end
      end

      private

      def save_and_complete
        transaction do
          planning_application.update!(site_history_checked: true)
          super
        end
      end
    end
  end
end
