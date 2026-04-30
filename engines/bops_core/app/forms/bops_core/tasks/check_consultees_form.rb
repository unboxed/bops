# frozen_string_literal: true

module BopsCore
  module Tasks
    module CheckConsulteesForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_draft save_and_complete]
      end

      def add_consultees_task_path
        if planning_application.pre_application?
          task_path(planning_application, "consultees/add-and-assign-consultees", return_to: task.url)
        else
          task_path(planning_application, "consultees-neighbours-and-publicity/consultees/add-and-assign-consultees", return_to: task.url)
        end
      end

      def determine_consultation_requirement_task_path
        task_path(planning_application, "consultees/determine-consultation-requirement", return_to: task.url)
      end

      private

      def save_and_complete
        super do
          planning_application.consultation.create_consultees_review!
        end
      end
    end
  end
end
