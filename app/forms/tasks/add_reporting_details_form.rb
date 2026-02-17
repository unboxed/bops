# frozen_string_literal: true

module Tasks
  class AddReportingDetailsForm < Form
    self.task_actions = %w[save_draft save_and_complete edit_form]

    attribute :reporting_type_id, :string
    attribute :regulation, :boolean
    attribute :regulation_3, :boolean
    attribute :regulation_4, :boolean

    validates :reporting_type_id, presence: {message: "Please select a development type for reporting"}, on: :save_and_complete, if: :selected_reporting_types?

    after_initialize :prefill_from_planning_application

    private

    def save_draft
      return false unless planning_application.update(reporting_details_params)

      super
    end

    def save_and_complete
      return false unless planning_application.update(reporting_details_params, :reporting_types)

      super
    end

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

    def selected_reporting_types?
      planning_application.application_type.selected_reporting_types?
    end
  end
end
