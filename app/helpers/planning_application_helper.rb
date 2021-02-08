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

  def proposed_or_existing(planning_application)
    planning_application.work_status == "proposed" ? "No" : "Yes"
  end

  def filter_text
    if current_user.assessor?
      "View my applications"
    else
      "View assessed applications"
    end
  end

  def list_constraints(constraints)
    JSON.parse(constraints).select { |_category, value| value == true }.keys unless constraints.empty?
  end

  def display_status(planning_application)
    if planning_application.determined?
      display_decision_status(planning_application)
    elsif planning_application.status == "invalidated"
      { color: "yellow", decision: "invalid" }
    elsif planning_application.status == "not_started"
      { color: "grey", decision: "Not started" }
    elsif planning_application.status == "in_assessment"
      { color: "turquoise", decision: "In assessment" }
    elsif planning_application.status == "awaiting_determination"
      { color: "purple", decision: "Awaiting determination" }
    elsif planning_application.status == "awaiting_correction"
      { color: "green", decision: "Awaiting correction" }
    else
      { color: "grey", decision: planning_application.status }
    end
  end

  def display_decision_status(planning_application)
    if planning_application.granted?
      { color: "green", decision: "Granted" }
    else
      { color: "red", decision: "Refused" }
    end
  end

  def cancelled_at(planning_application)
    if planning_application.withdrawn?
      planning_application.withdrawn_at
    elsif planning_application.returned?
      planning_application.returned_at
    end
  end

  def proposal_step_mark_completed?(step_name, application)
    case step_name
    when "Check documents"
      application.not_started? == false
    when "Assess the proposal"
      application.assessor_decision&.valid?
    when "Reassess the proposal"
      application.assessor_decision_updated?
    when "Review the recommendation"
      application.reviewer_decision&.valid? &&
        application.reviewer_decision_updated?
    when "View the assessment"
      application.determined?
    else
      false
    end
  end

  def recommendation_step_mark_completed?(step_name, application)
    case step_name
    when "Submit the recommendation"
      application.awaiting_determination?
    when "Publish the recommendation"
      application.determined?
    when "View the decision notice"
      application.determined?
    else
      false
    end
  end
end
