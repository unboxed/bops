# frozen_string_literal: true

class ReviewImmunityDetailPermittedDevelopmentRightForm
  include ActiveModel::Model
  include CommitMatchable

  attr_accessor :planning_application, :params

  with_options presence: true do
    validates :decision, :decision_reason
    validates :summary, if: :decision_is_yes?
    validates :removed_reason, if: :removed
  end

  validates :removed, inclusion: { in: [true, false], if: :decision_is_no? }

  delegate(
    :decision,
    :decision_reason,
    :decision_type,
    :summary,
    to: :review_immunity_detail
  )

  delegate(
    :removed,
    :removed_reason,
    to: :permitted_development_right
  )

  def initialize(planning_application:, params: {})
    @params = params
    @review_immunity_detail_params = build_review_immunity_detail_params
    @permitted_development_right_params = params[:permitted_development_right]

    @review_immunity_detail = planning_application.immunity_detail.review_immunity_details.new(
      review_immunity_detail_params
    )
    @permitted_development_right = planning_application.permitted_development_rights.new(
      @permitted_development_right_params
    )
  end

  def save
    build_review_immunity_detail
    build_permitted_development_right

    return false unless valid?

    ActiveRecord::Base.transaction do
      review_immunity_detail.save!
      permitted_development_right.save! if decision_is_no?

      true
    end
  end

  private

  attr_reader :review_immunity_detail_params, :permitted_development_right_params,
              :review_immunity_detail, :permitted_development_right

  def decision_is_yes?
    review_immunity_detail_params["decision"] == "Yes"
  end

  def decision_is_no?
    review_immunity_detail_params["decision"] == "No"
  end

  def build_review_immunity_detail_params
    return if params.blank?

    review_immunity_detail_params = params[:review_immunity_detail]
    review_immunity_detail_params["decision_reason"] = (review_immunity_detail_params["yes_decision_reason"].presence ||
      review_immunity_detail_params["no_decision_reason"].presence)

    review_immunity_detail_params.except("yes_decision_reason", "no_decision_reason")
  end

  def build_review_immunity_detail
    review_immunity_detail.tap do |record|
      record.assessor = Current.user
      record.decision_reason = (decision_reason.presence || decision_type)
    end
  end

  def build_permitted_development_right
    return unless decision_is_no?

    permitted_development_right.tap do |record|
      record.assessor = Current.user
      record.status = permitted_development_right_status
    end
  end

  def permitted_development_right_status
    return "in_progress" if save_progress?

    case permitted_development_right_params[:removed]
    when "true"
      "removed"
    when "false"
      "checked"
    end
  end
end