# frozen_string_literal: true

class RecommendationForm
  include ActiveModel::Model

  attr_accessor :recommendation

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
        recommendation.save(validate: false)
      else
        planning_application.save!
        recommendation.save!
        planning_application.assess!
      end
    end
  end

  def decisions
    ldc? ? ldc_decisions : pa_decisions
  end

  def decisions_text
    ldc? ? ldc_decisions_text : pa_decisions_text
  end

  def reason_text
    I18n.t(".recommendations.new.state_the_reason.#{application_type_name}")
  end

  private

  def ldc?
    application_type_name == "lawfulness_certificate"
  end

  def ldc_decisions
    [
      [:refused, I18n.t(".recommendations.new.no")],
      [:granted, I18n.t(".recommendations.new.yes")]
    ]
  end

  def pa_decisions
    [
      [:refused, I18n.t("recommendation.prior_approval.refused")],
      [:granted, I18n.t("recommendation.prior_approval.granted")],
      [:granted_not_required,
       I18n.t("recommendation.prior_approval.granted_not_required")]
    ]
  end

  def ldc_decisions_text
    I18n.t(".recommendations.new.ldc_is_the_use")
  end

  def pa_decisions_text
    I18n.t(".recommendations.new.pa_is_the_use")
  end
end
