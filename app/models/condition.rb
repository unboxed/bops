# frozen_string_literal: true

class Condition < ApplicationRecord
  belongs_to :condition_set
  acts_as_list scope: :condition_set

  has_many :validation_requests, as: :owner, dependent: :destroy

  validates :text, :reason, presence: true
  validates :title, presence: true, if: :pre_commencement?
  validate :ensure_planning_application_not_closed_or_cancelled, on: :update

  attribute :reviewer_edited, :boolean, default: false

  delegate :current_review, to: :condition_set
  delegate :not_started?, to: :current_review, prefix: true
  delegate :planning_application, to: :condition_set

  before_update if: :reviewer_edited? do
    current_review.update!(reviewer_edited: true)
  end

  after_create if: :current_review_not_started? do
    current_review.update!(status: "in_progress") unless standard?
  end

  after_create :create_validation_request!, if: :pre_commencement?
  before_update :create_validation_request!, if: -> { pre_commencement? && should_create_validation_request? }

  scope :not_cancelled, -> { where(cancelled_at: nil) }

  def checked?
    persisted? || errors.present?
  end

  def review_title
    title.presence || "Other"
  end

  def current_validation_request
    validation_requests.order(:created_at).last
  end

  def text_and_reason
    text + "\n\n" + reason
  end

  private

  def should_create_validation_request?
    return if current_review.complete?
    return unless current_validation_request.closed?

    title_changed? || text_changed? || reason_changed?
  end

  def create_validation_request!
    validation_requests.pre_commencement_conditions.create!(planning_application: planning_application, post_validation: true, user: Current.user)
  end

  def pre_commencement?
    condition_set.pre_commencement?
  end

  def ensure_planning_application_not_closed_or_cancelled
    errors.add(:base, "Cannot modify conditions when planning application has been closed or cancelled") if planning_application.closed_or_cancelled?
  end
end
