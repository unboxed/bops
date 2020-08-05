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

  def proposal_step_mark_completed?(step_name, application)
    case step_name
    when "Assess the proposal"
      application.assessor_decision&.valid?
    when "Review the recommendation"
      application.reviewer_decision&.valid?
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
