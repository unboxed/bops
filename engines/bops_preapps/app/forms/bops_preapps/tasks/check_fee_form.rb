# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class CheckFeeForm < BaseForm
      include ActiveModel::Attributes

      attribute :valid_fee, :boolean

      validates :valid_fee, inclusion: {in: [true, false], message: :blank}

      def update(params)
        assign_attributes(valid_fee: params.dig(:planning_application, :valid_fee))
        save
      end

      def save
        return false unless valid?

        ApplicationRecord.transaction do
          planning_application.update!(valid_fee:)
          valid_fee ? task.complete! : task.in_progress!
        end
        true
      rescue ActiveRecord::RecordInvalid
        false
      end

      def redirect_url
        if valid_fee
          task_path(planning_application, task)
        else
          Rails.application.routes.url_helpers.new_planning_application_validation_validation_request_path(
            planning_application,
            type: "fee_change"
          )
        end
      end

      def permitted_fields(params)
        params
      end
    end
  end
end
