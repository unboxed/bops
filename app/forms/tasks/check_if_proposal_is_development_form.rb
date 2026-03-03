# frozen_string_literal: true

module Tasks
  class CheckIfProposalIsDevelopmentForm < Form
    self.task_actions = %w[save_and_complete save_draft]

    attribute :section_55_development, :boolean

    after_initialize do
      self.section_55_development = planning_application.section_55_development
    end

    with_options on: :save_and_complete do
      validates :section_55_development, inclusion: {in: [true, false], message: "Select whether the application is development."}
    end

    private

    def save_and_complete
      transaction do
        planning_application.update!(section_55_development:)

        if section_55_development == false
          planning_application.planning_application_policy_classes.destroy_all
        end

        super
      end
    end

    def save_draft
      transaction do
        planning_application.update!(section_55_development:)

        super
      end
    end
  end
end
