# frozen_string_literal: true

class Term < ApplicationRecord
  has_many :validation_requests, as: :owner, class_name: "ValidationRequest", dependent: :destroy
  belongs_to :heads_of_term
  acts_as_list scope: :heads_of_term

  validates :text, :title, presence: true

  attribute :reviewer_edited, :boolean, default: false

  delegate :current_review, to: :heads_of_term
  delegate :not_started?, to: :current_review, prefix: true
  delegate :planning_application, to: :heads_of_term

  before_update if: :reviewer_edited? do
    current_review.update!(reviewer_edited: true)
  end

  after_create if: :current_review_not_started? do
    current_review.update!(status: "in_progress")
  end

  after_create :create_validation_request
  before_update :create_validation_request, if: :should_create_validation_request?
  scope :not_cancelled, -> { where(cancelled_at: nil) }

  def current_validation_request
    validation_requests.order(:created_at).last
  end

  def checked?
    persisted? || errors.present?
  end

  private

  def should_create_validation_request?
    return if current_review.complete?
    return unless current_validation_request&.closed?

    title_changed? || text_changed?
  end

  def create_validation_request
    ValidationRequest.create!(type: "HeadsOfTermsValidationRequest", planning_application: heads_of_term.planning_application, post_validation: true, user: Current.user, owner: self)
  end
end
