# frozen_string_literal: true

module Tasks
  class CheckDescriptionForm < Form
    include BopsCore::Tasks::CheckDescriptionForm

    attribute :proposed_description
    attribute :skip_applicant_approval

    with_options on: :save_and_complete do
      validates :skip_applicant_approval,
        inclusion: {in: ["true", "false"], message: "Select whether the applicant's approval is required for this change"},
        if: -> { params[param_key][:valid_description] != "true" }

      validates :proposed_description, presence: true, if: -> { params[param_key][:valid_description] != "true" }
    end

    def redirect_url(options = {})
      url
    end

    private

    def save_and_complete
      transaction do
        if valid_description == false
          # raise
          planning_application.validation_requests.create!(
            type: "DescriptionChangeValidationRequest",
            proposed_description:,
            skip_applicant_approval:,
            user: Current.user
          )
        end

        planning_application.update!(valid_description:)
        if valid_description || skip_applicant_approval
          task.complete!
        else
          task.in_progress!
        end
      end
    end
  end
end
