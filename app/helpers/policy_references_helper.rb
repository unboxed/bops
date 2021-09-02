# frozen_string_literal: true

module PolicyReferencesHelper
  def checkboxes_for_policy_classes_for_part(number)
    classes = PlanningApplication.classes_for_part(number)

    classes.map { |c| [c[:id], c[:name]] }
  end

  def policy_class_already_selected?(part, klass)
    @planning_application.policy_classes.find do |c|
      c["id"] == klass and c["part"] = part
    end
  end
end
