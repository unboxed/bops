# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class DetermineConsultationRequirementForm < Form
      attribute :consultation_required, :boolean

      with_options on: :save_and_complete do
        validates :consultation_required,
          inclusion: {in: [true, false], message: "Determine if consultation is required"}
      end

      after_initialize do
        self.consultation_required = planning_application.consultation_required
      end

      def update(params)
        super do
          save_and_complete
        end
      end

      def consultation_required?
        consultation_required
      end

      private

      def save_and_complete
        transaction do
          planning_application.update!(consultation_required:)
          update_consultation_tasks_visibility
          task.complete!
        end
      end

      def update_consultation_tasks_visibility
        return unless consultation_required

        consultees_section = case_record.tasks.find_by(slug: "consultees")
        return unless consultees_section

        consultees_section.tasks.where(hidden: true).update_all(hidden: false)
      end
    end
  end
end
