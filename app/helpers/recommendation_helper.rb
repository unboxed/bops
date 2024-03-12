# frozen_string_literal: true

module RecommendationHelper
  def other_committee_decision_reasons(reasons)
    reasons.nil? ? [] : (reasons.to_a - CommitteeDecision::REASONS)[0]
  end

  def report_or_notice?(planning_application)
    planning_application&.committee_decision&.recommend? ? "report" : "notice"
  end
end
