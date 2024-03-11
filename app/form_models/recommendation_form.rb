# frozen_string_literal: true

class RecommendationForm
  include ActiveModel::Model

  attr_accessor :recommendation, :other_reason, :reasons, :recommend

  validates :decision, :public_comment, presence: true

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
    pa? ? prior_approval_decisions : granted_and_refused
  end

  def decisions_text
    I18n.t(".planning_applications.assessment.recommendations.new.is_the_use.#{application_type_name}")
  end

  def reason_text
    I18n.t(".planning_applications.assessment.recommendations.new.state_the_reason.#{application_type_name}")
  end

  def committee_decision
    CommitteeDecision.build(planning_application:, recommend:, reasons: updated_reasons)
  end

  def updated_reasons
    reasons.push(other_reason).reject(&:empty?)
  end

  private

  def pa?
    application_type_name == "prior_approval"
  end

  def granted_and_refused
    [
      [:refused, I18n.t(".planning_applications.assessment.recommendations.new.decision.#{application_type_name}.refused")],
      [:granted, I18n.t(".planning_applications.assessment.recommendations.new.decision.#{application_type_name}.granted")]
    ]
  end

  def prior_approval_decisions
    granted_and_refused.push(granted_not_required)
  end

  def granted_not_required
    [:granted_not_required, I18n.t(".planning_applications.assessment.recommendations.new.decision.#{application_type_name}.granted_not_required")]
  end

  def committee_decision_present?
    planning_application.committee_decision.present?
  end
end
