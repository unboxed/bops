# frozen_string_literal: true

class RecommendationForm
  include ActiveModel::Model

  attr_accessor :recommendation, :other_reason, :reasons, :recommend

  validates :decision, :public_comment, presence: true

  validate do
    errors.add(:reasons, "Choose reasons why this application should go to committee") if updated_reasons.empty? && recommend == "true"
  end

  delegate(
    :planning_application,
    :assessor_comment,
    :assessment_in_progress?,
    "assessor_comment=",
    "assessor=",
    "status=",
    to: :recommendation
  )

  delegate(
    :public_comment,
    "public_comment=",
    :decision,
    "decision=",
    :application_type_name,
    to: :planning_application
  )

  def save
    return false unless assessment_in_progress? || valid?

    ActiveRecord::Base.transaction do
      if assessment_in_progress?
        planning_application.save_assessment
        recommendation.save!(validate: false)
      else
        planning_application.save!
        recommendation.save!

        if committee_decision_present?
          planning_application.committee_decision.update!(reasons: updated_reasons, recommend:)
        else
          committee_decision.save!
        end

        planning_application.assess!
      end
    end
  end

  def decisions
    planning_application.recommendation_options
  end

  def committee_decision
    CommitteeDecision.build(planning_application:, recommend:, reasons: updated_reasons)
  end

  def updated_reasons
    return [] if reasons.nil?

    reasons.push(other_reason).compact_blank
  end

  private

  def committee_decision_present?
    planning_application.committee_decision.present?
  end
end
