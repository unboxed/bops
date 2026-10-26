# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class CheckDescriptionForm < Form
      attribute :description, :string

      def redirect_url
        edit_task_path(enforcement, task.parent)
      end

      private

      def save_and_complete
        super do
          enforcement.update!(description:)
          task.parent.in_progress! if task.parent.not_started!
        end
      end
    end
  end
end
