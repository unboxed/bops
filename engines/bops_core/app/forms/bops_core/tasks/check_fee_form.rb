# frozen_string_literal: true

module BopsCore
  module Tasks
    module CheckFeeForm
      extend ActiveSupport::Concern

      included do
        self.task_actions = %w[save_and_complete update_request delete_request edit_form]

        class_attribute :reference_param_name, default: :reference

        attribute :valid_fee, :boolean
        attribute :reason, :string
        attribute :suggestion, :string
        attribute :validation_request_id, :integer
        attribute :payment_amount, :string

        with_options on: :save_and_complete do
          validates :valid_fee, inclusion: {in: [true, false], message: "Select whether the fee is correct"}
          validates :reason, presence: {message: "Tell the applicant why the fee is incorrect"}, unless: :valid_fee?
          validates :suggestion, presence: {message: "Tell the applicant what they need to do"}, unless: :valid_fee?
        end

        with_options on: :update_request do
          validates :reason, presence: {message: "Tell the applicant why the fee is incorrect"}
          validates :suggestion, presence: {message: "Tell the applicant what they need to do"}
        end

        after_initialize do
          self.valid_fee = planning_application.valid_fee
        end
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
          when "edit_form"
            task.in_progress!
          end
        end
      end

      def validation_request
        @validation_request ||= if validation_request_id.present?
          planning_application.fee_change_validation_requests.find(validation_request_id)
        else
          planning_application.fee_change_validation_requests.open_or_pending.first ||
            planning_application.fee_change_validation_requests.closed.last
        end
      end

      def edit_url
        route_for(:edit_task, planning_application, task, validation_request_id: validation_request&.id, return_to: return_to, only_path: true)
      end

      def cancel_url
        route_for(
          :new_validation_request_cancellation,
          reference_param_name => planning_application.reference,
          :validation_request_id => validation_request.id,
          :task_slug => task.full_slug,
          :only_path => true
        )
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
        end
      end

      private

      def valid_fee?
        valid_fee
      end

      def save_and_complete
        transaction do
          if valid_fee
            planning_application.tap do |pa|
              pa.valid_fee = true
              pa.payment_amount = payment_amount if payment_amount.present?
            end.save!
          else
            planning_application.update!(valid_fee: false)
            create_validation_request!
          end
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
