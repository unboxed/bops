# frozen_string_literal: true

module Tasks
  class CheckDescriptionForm < Form
    include BopsCore::Tasks::CheckDescriptionForm

    attribute :proposed_description
    attribute :skip_applicant_approval, :boolean

    with_options on: :save_and_complete do
      validates :skip_applicant_approval,
        inclusion: {in: [true, false], message: "Select whether the applicant's approval is required for this change"},
        unless: :valid_description

      validates :proposed_description, presence: true, unless: :valid_description
    end

    def cancellation_path
      main_app.new_validation_request_cancellation_path(
        planning_application.reference,
        validation_request.id,
        task_slug: task.full_slug
      )
    end

    private

    def save_and_complete
      transaction do
        planning_application.update!(valid_description:)
        # specifically comparing with false because nil is treated differently
        if valid_description == false
          planning_application.validation_requests.create!(
            type: "DescriptionChangeValidationRequest",
            proposed_description:,
            skip_applicant_approval:,
            user: Current.user
          )
        end

        if valid_description || skip_applicant_approval
          task.complete!
        else
          task.in_progress!
        end
      end
    end
  end
end
