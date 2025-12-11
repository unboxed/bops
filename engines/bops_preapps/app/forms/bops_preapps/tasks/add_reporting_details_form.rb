# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class AddReportingDetailsForm < Form
      self.task_actions = %w[save_draft save_and_complete]

      attribute :reporting_type_id, :string
      attribute :regulation, :boolean
      attribute :regulation_3, :boolean
      attribute :regulation_4, :boolean

      after_initialize :prefill_from_planning_application

      def update(params)
        super do
          transaction do
            return false unless planning_application.update(reporting_details_params, :reporting_types)

            case action
            when "save_draft"
              save_draft
            when "save_and_complete"
              save_and_complete
            else
              raise ArgumentError, "Invalid task action: #{action.inspect}"
            end
          end
        end
      rescue ActiveRecord::RecordInvalid
        false
      end

      private

      def prefill_from_planning_application
        self.reporting_type_id ||= planning_application.reporting_type_id
        self.regulation ||= planning_application.regulation
        self.regulation_3 ||= planning_application.regulation_3
        self.regulation_4 ||= planning_application.regulation_4
      end

      def reporting_details_params
        regulation_present = ActiveModel::Type::Boolean.new.cast(regulation)
        regulation_3_selected = ActiveModel::Type::Boolean.new.cast(regulation_3)

        {
          reporting_type_id:,
          regulation: regulation_present,
          regulation_3: regulation_present && regulation_3_selected,
          regulation_4: regulation_present && !regulation_3_selected
        }
      end

      def save_draft
        task.start!
      end

      def save_and_complete
        task.complete!
      end
    end
  end
end
