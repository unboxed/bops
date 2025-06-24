# frozen_string_literal: true

class ConditionSet < ApplicationRecord
  belongs_to :planning_application

  with_options dependent: :destroy do
    has_many :conditions, -> { order(position: :asc) }
    has_many :reviews, -> { order(created_at: :desc) }, as: :owner
  end

  has_many :validation_requests, through: :conditions

  accepts_nested_attributes_for :conditions, allow_destroy: true
  accepts_nested_attributes_for :reviews

  after_update :create_review, if: :should_create_review?

  before_create unless: :pre_commencement? do
    I18n.t(:conditions_list).each do |condition|
      conditions.new(condition)
    end
  end

  def current_review
    reviews.load.first || reviews.create!
  end

  def approved_conditions
    conditions.joins(:validation_requests).where(validation_requests: {approved: true}).distinct
  end

  def not_cancelled_conditions
    conditions.not_cancelled
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

  def latest_validation_request
    validation_requests.notified.max_by(&:notified_at)
  end

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
    reviews.create!(assessor: Current.user, status:)
  end
end
