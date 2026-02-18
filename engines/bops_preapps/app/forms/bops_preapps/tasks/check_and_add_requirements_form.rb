# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckAndAddRequirementsForm < Form
      self.task_actions = %w[add_requirement remove_requirement save_draft save_and_complete]
      attribute :new_requirement_ids, :list
      attribute :requirement_id, :integer

      private

      def add_requirement
        transaction do
          planning_application.add_requirements(new_requirements)
          task.start!
        end
      end

      def remove_requirement
        transaction do
          requirement = planning_application.requirements.find(requirement_id)
          requirement.destroy!
          task.start!
        end
      end

      def new_requirements
        local_authority.requirements.where(id: new_requirement_ids.compact_blank)
      end

      def form_params(params)
        params.fetch(param_key, {}).permit(:requirement_id, new_requirement_ids: [])
      end
    end
  end
end
