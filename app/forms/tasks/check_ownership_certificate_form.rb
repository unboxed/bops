# frozen_string_literal: true

module Tasks
  class CheckOwnershipCertificateForm < Form
    self.task_actions = %w[save_and_complete edit_form]

    attribute :valid_ownership_certificate, :boolean
    attribute :invalidated_ownership_reason, :string

    after_initialize do
      self.valid_ownership_certificate = planning_application.valid_ownership_certificate
      if valid_ownership_certificate == false
        request = planning_application.ownership_certificate_validation_requests.open_or_pending.first
        self.invalidated_ownership_reason = request&.reason
      end
    end

    with_options on: :save_and_complete do
      validates :valid_ownership_certificate, inclusion: {in: [true, false, "true", "false"], message: "Select whether the ownership certificate is valid."}
      validates :invalidated_ownership_reason, presence: {message: "Explain why the ownership certificate is invalid"}, if: :ownership_certificate_invalid?
    end

    def update(params)
      super do
        case action
        when "save_and_complete" then save_and_complete
        when "edit_form" then edit_form
        end
      end
    end

    private

    def ownership_certificate_invalid?
      valid_ownership_certificate.to_s == "false"
    end

    def save_and_complete
      transaction do
        planning_application.update!(
          valid_ownership_certificate: valid_ownership_certificate,
          ownership_certificate_checked: true
        )

        existing_request = planning_application.ownership_certificate_validation_requests.open_or_pending.first

        if ownership_certificate_invalid?
          if existing_request
            existing_request.update!(reason: invalidated_ownership_reason)
          else
            planning_application.ownership_certificate_validation_requests.create!(
              reason: invalidated_ownership_reason,
              user: Current.user
            )
          end
        elsif existing_request
          existing_request.destroy!
        end

        task.completed!
      end
    end
  end
end
