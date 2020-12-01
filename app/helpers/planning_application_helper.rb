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

  def filter_text
    if current_user.assessor?
      "View my applications"
    else
      "View assessed applications"
    end
  end

  def application_status(application)
    case application.status
    when "not_started"
      "Not started"
    when "awaiting_validation"
      "Awaiting validation"
    when "new_documents_requested"
      "Awaiting documents"
    when "in_assessment"
      "In assessment"
    when "awaiting_determination"
      "Awaiting determination"
    when "awaiting_correction"
      "Awaiting correction"
    when "determined"
      "Determined"
    end
  end

  # rubocop: disable Metrics/MethodLength
  def proposal_step_mark_completed?(step_name, application)
    case step_name
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
  # rubocop: enable Metrics/MethodLength

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

  def assessor_decision_path(app)
    if app.assessor_decision
      if app.assessment_complete?
        planning_application_decision_path(app, app.assessor_decision)
      else
        edit_planning_application_decision_path(app, app.assessor_decision)
      end
    else
      new_planning_application_decision_path(app)
    end
  end

  def reviewer_decision_path(app)
    if app.reviewer_decision
      if app.review_complete?
        planning_application_decision_path(app, app.reviewer_decision)
      else
        edit_planning_application_decision_path(app, app.reviewer_decision)
      end
    else
      new_planning_application_decision_path(app)
    end
  end
end
