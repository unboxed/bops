# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckFeeForm < Form
      self.task_actions = %w[save_and_complete update_request delete_request cancel_request]

      attribute :valid_fee, :boolean
      attribute :reason, :string
      attribute :suggestion, :string
      attribute :cancel_reason, :string
      attribute :validation_request_id, :integer

      with_options on: :save_and_complete do
        validates :valid_fee, inclusion: {in: [true, false], message: "Select whether the fee is correct"}
        validates :reason, presence: {message: "Tell the applicant why the fee is incorrect"}, unless: :valid_fee?
        validates :suggestion, presence: {message: "Tell the applicant what they need to do"}, unless: :valid_fee?
      end

      with_options on: :update_request do
        validates :reason, presence: {message: "Tell the applicant why the fee is incorrect"}
        validates :suggestion, presence: {message: "Tell the applicant what they need to do"}
      end

      with_options on: :cancel_request do
        validates :cancel_reason, presence: {message: "Explain to the applicant why this request is being cancelled"}
      end

      after_initialize do
        self.valid_fee = planning_application.valid_fee
      end

      def update(params)
        super do
          case action
          when "save_and_complete"
            save_and_complete
          when "update_request"
            update_validation_request
          when "delete_request"
            delete_validation_request
          when "cancel_request"
            cancel_validation_request
          end
        end
      end

      def validation_request
        @validation_request ||= if validation_request_id.present?
          planning_application.fee_change_validation_requests.find(validation_request_id)
        else
          planning_application.fee_change_validation_requests.open_or_pending.first
        end
      end

      def edit_url
        route_for(:edit_task, planning_application, task, validation_request_id: validation_request&.id, only_path: true)
      end

      def cancel_url
        route_for(:cancel_task, planning_application, task, validation_request_id: validation_request&.id, only_path: true)
      end

      def flash(type, controller)
        return nil unless type == :notice && after_success == "redirect"

        case action
        when "save_and_complete"
          controller.t(".check-fee.success")
        when "update_request"
          controller.t(".check-fee.update_request")
        when "delete_request"
          controller.t(".check-fee.delete_request")
        when "cancel_request"
          controller.t(".check-fee.cancel_request")
        end
      end

      private

      def valid_fee?
        valid_fee
      end

      def save_and_complete
        transaction do
          planning_application.update!(valid_fee:)

          create_validation_request! unless valid_fee
          task.complete!
        end
      end

      def update_validation_request
        validation_request.update!(reason:, suggestion:)
      end

      def delete_validation_request
        transaction do
          validation_request.destroy!
          task.not_started!
        end
      end

      def cancel_validation_request
        transaction do
          validation_request.assign_attributes(cancel_reason:)
          validation_request.cancel_request!
          task.not_started!
        end
      end

      def create_validation_request!
        planning_application.fee_change_validation_requests.create!(
          reason:,
          suggestion:,
          user: Current.user
        )
      end
    end
  end
end
