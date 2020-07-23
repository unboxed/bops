# frozen_string_literal: true

module PlanningApplicationHelper
  def days_color(days_left)
    if days_left > 11
      "green"
    elsif days_left.between?(6, 10)
      "yellow"
    else
      "red"
    end
  end

  def exclude_others?
    params[:q] == "exclude_others"
  end

  def mark_completed?(step_name, application)
    if step_name == "Assess the proposal" || "Submit the recommendation"
      true if application.assessor_decision&.valid?
    elsif step_name == "Reassess the proposal"
      true unless application.correction_requested?
    elsif step_name == "Resubmit the recommendation"
      true if application.correction_provided?
    elsif step_name == "Review the recommendation" || "Review the corrections"
      true if application.reviewer_decision&.valid?
    end
  end
end
