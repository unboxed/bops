# frozen_string_literal: true

module Tasks
  class CheckOwnershipCertificateForm < Form
    self.task_actions = %w[save_and_complete update_request delete_request edit_form assessment_complete]

    attribute :valid_ownership_certificate, :boolean
    attribute :invalidated_ownership_reason, :string
    attribute :validation_request_id, :integer
    attribute :reason, :string
    attribute :ownership_certificate_post_validation_reason, :string

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

    with_options on: :update_request do
      validates :reason, presence: {message: "Tell the applicant why the ownership certificate is incorrect"}
    end

    def validation_request
      @validation_request ||= if validation_request_id.present?
        planning_application.ownership_certificate_validation_requests.find(validation_request_id)
      else
        planning_application.ownership_certificate_validation_requests.open_or_pending.first ||
          planning_application.ownership_certificate_validation_requests.closed.last
      end
    end

    def cancel_url
      route_for(
        :new_validation_request_cancellation,
        planning_application_reference: planning_application.reference,
        validation_request_id: validation_request.id,
        task_slug: task.full_slug,
        only_path: true
      )
    end

    def edit_url
      route_for(:edit_task, planning_application, task, validation_request_id: validation_request&.id, return_to: return_to, only_path: true)
    end

    def flash(type, controller)
      return nil unless type == :notice && after_success == "redirect"

      case action
      when "save_and_complete", "assessment_complete"
        controller.t(".check-ownership-certificate.success")
      when "update_request"
        controller.t(".check-ownership-certificate.update_request")
      when "delete_request"
        controller.t(".check-ownership-certificate.delete_request")
      end
    end

    def validation_requests
      planning_application.ownership_certificate_validation_requests
    end

    private

    def ownership_certificate_invalid?
      valid_ownership_certificate.to_s == "false"
    end

    def save_and_complete
      # only used for validation task, assesment task uses assessment_complete method
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

    def delete_request
      transaction do
        validation_request.destroy!
        task.not_started!
      end
    end

    def update_request
      validation_request.update!(reason:)
    end

    def assessment_complete
      unless ownership_certificate_post_validation_reason.blank?
        planning_application.ownership_certificate_validation_requests.create!(
          reason: ownership_certificate_post_validation_reason,
          user: Current.user
        )
      end

      task.completed!
    end
  end
end
