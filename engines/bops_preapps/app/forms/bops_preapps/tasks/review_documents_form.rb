# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class ReviewDocumentsForm < Form
      self.task_actions = %w[save_draft save_and_complete]

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

      def save_draft
        task.start!
      end

      def save_and_complete
        task.complete!
      end
    end
  end
end
