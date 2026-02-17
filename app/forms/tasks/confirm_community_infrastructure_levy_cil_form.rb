# frozen_string_literal: true

module Tasks
  class ConfirmCommunityInfrastructureLevyCilForm < Form
    self.task_actions = %w[save_and_complete edit_form]

    attribute :cil_liable, :boolean

    with_options on: :save_and_complete do
      validates :cil_liable, inclusion: {in: [true, false, "true", "false"], message: "Select whether the application is liable for CIL."}
    end

    def recommended_cil_liable
      if planning_application.likely_cil_exempt?
        false
      elsif planning_application.likely_cil_liable?
        true
      end
    end

    private

    def save_and_complete
      transaction do
        planning_application.update!(cil_liable: cil_liable)
        task.completed!
      end
    end
  end
end
