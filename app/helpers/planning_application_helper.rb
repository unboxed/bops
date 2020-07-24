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

  def assess_proposal_step_name(planning_application)
    if planning_application.correction?
      step_name = "Reassess the proposal"
    else
      step_name = "Assess the proposal"
    end
  end

  def submit_proposal_step_name(planning_application)
    if planning_application.correction?
      step_name = "Resubmit the recommendation"
    else
      step_name = "Submit the recommendation"
    end
  end

  def review_proposal_step_name(planning_application)
    if planning_application.correction?
      step_name = "Review the corrections"
    else
      step_name = "Review the recommendation"
    end
  end
end
