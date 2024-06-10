# frozen_string_literal: true

class Term < ApplicationRecord
  has_many :validation_requests, as: :owner, class_name: "ValidationRequest", dependent: :destroy
  belongs_to :heads_of_term
  acts_as_list scope: :heads_of_term

  validates :text, :title, presence: true

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
    return unless current_validation_request.closed?
    title_changed? || text_changed?
  end

  def create_validation_request
    ValidationRequest.create!(type: "HeadsOfTermsValidationRequest", planning_application: heads_of_term.planning_application, post_validation: true, user: Current.user, owner: self)
  end
end
