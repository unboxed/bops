# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  belongs_to :planning_application
  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review"
  has_many :conditions, -> { order(position: :asc) }, dependent: :destroy
  has_many :validation_requests, through: :conditions

  accepts_nested_attributes_for :conditions, allow_destroy: true
  accepts_nested_attributes_for :reviews

  after_create :create_standard_conditions, unless: :pre_commencement?
  after_create :create_review
  after_update :create_review, if: :should_create_review?

  def current_review
    reviews.order(:created_at).last
  end

  def latest_validation_request
    validation_requests.notified.max_by(&:notified_at)
  end

  def latest_validation_requests
    validation_requests.group_by(&:owner_id).map { |id, vr| vr.max_by(&:notified_at) }
  end

  def latest_active_validation_requests
    latest_validation_requests.select { |vr| vr.state != "cancelled" }
  end

  def approved_conditions
    conditions.joins(:validation_requests).where(validation_requests: {approved: true})
  end

  def confirm_pending_requests!
    transaction do
      validation_requests.pending.each(&:mark_as_sent!)

      create_or_update_review!("complete")
    end

    send_pre_commencement_condition_request_email
  end

  def create_or_update_review!(status)
    if current_review.present?
      if current_review.review_complete?
        create_review(status)
      else
        current_review.update!(status:)
      end
    else
      create_review(status)
    end
  end

  private

  def send_pre_commencement_condition_request_email
    PlanningApplicationMailer.pre_commencement_condition_request_mail(
      planning_application,
      latest_validation_request
    ).deliver_now
  end

  def should_create_review?
    return if current_review.nil?
    current_review.status == "updated" && current_review.review_status == "to_be_reviewed"
  end

  def create_review(status = :not_started)
    reviews.create!(assessor: Current.user, owner_type: "ConditionSet", owner_id: id, status:)
  end

  def create_standard_conditions
    Condition.standard_conditions.each { |condition| condition.update!(condition_set: self) }
  end
end
