# frozen_string_literal: true

module BopsCore
  module Tasks
    module CheckConsulteesForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_draft save_and_complete]
      end

      def add_consultees_task_path
        task_path(planning_application, "consultees/add-and-assign-consultees")
      end

      def determine_consultation_requirement_task_path
        task_path(planning_application, "consultees/determine-consultation-requirement")
      end

      private

      def save_and_complete
        ActiveRecord::Base.transaction do
          planning_application.consultation.create_consultees_review!
          task.complete!
        end
      end
    end
  end
end
