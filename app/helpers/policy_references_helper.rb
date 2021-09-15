# frozen_string_literal: true

module PolicyReferencesHelper
  def checkboxes_for_policy_classes_for_part(number)
    classes = PlanningApplication.classes_for_part(number)

    classes.map { |c| [c[:id], c[:name]] }
  end

  def policy_class_already_selected?(part, klass)
    @planning_application.find_policy_class(part, klass)
  end

  def policy_class_status(klass)
    return "undetermined" if klass["policies"].any? { |p| p["status"] == "undetermined" }
    return "does not comply" if klass["policies"].any? { |p| p["status"] == "does_not_comply" }

    "complies"
  end

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

  def part_and_class(klass)
    "Part #{klass['part']}, Class #{klass['id']}"
  end
end
