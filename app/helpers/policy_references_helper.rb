# frozen_string_literal: true

module PolicyReferencesHelper
  def class_for_policy_class_status(status)
    classes = %w[govuk-tag app-task-list__task-tag]

    colour = case status
             when "does not comply"
               "red"
             when "complies"
               "green"
             end

    classes.append "govuk-tag--#{colour}" if colour.present?

    classes.join(" ")
  end
end
