# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckConsulteesConsultedForm < Form
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

      def add_consultees_task
        task.case_record.find_task_by_slug_path!("consultees/add-and-assign-consultees")
      end

      def determine_consultation_requirement_task
        task.case_record.find_task_by_slug_path!("consultees/determine-consultation-requirement")
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
