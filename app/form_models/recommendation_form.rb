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
end
