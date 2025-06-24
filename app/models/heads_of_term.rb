# frozen_string_literal: true

class HeadsOfTerm < ApplicationRecord
  belongs_to :planning_application

  with_options dependent: :destroy do
    has_many :terms, -> { order(position: :asc) }, extend: TermsExtension
    has_many :reviews, -> { order(created_at: :desc) }, as: :owner
  end

  has_many :validation_requests, through: :terms

  accepts_nested_attributes_for :terms, allow_destroy: true
  accepts_nested_attributes_for :reviews

  after_update :create_heads_of_terms_review!, if: :should_create_review?
  after_commit :update_validation_requests, if: :public?

  def current_review
    reviews.load.first || reviews.create!
  end

  def any_new_updated_validation_requests?
    validation_requests.requests_created_later(current_review).any? { |validation_request| !validation_request.approved.nil? }
  end

  def create_heads_of_terms_review!
    reviews.create!(reviewer: Current.user, owner_id: id, specific_attributes: {"review_type" => "heads_of_term"}, status: "complete")
  end

  def update_validation_requests
    validation_requests.pending.each { |request| request.email_and_timestamp }
  end

  def confirm_pending_requests!
    transaction do
      validation_requests.pending.each(&:mark_as_sent!)

      create_heads_of_terms_review!
    end

    latest_validation_request.send_post_validation_request_email
  end

  def not_cancelled_terms
    terms.not_cancelled
  end

  private

  def latest_validation_request
    validation_requests.notified.max_by(&:notified_at)
  end

  def should_create_review?
    return if current_review.nil?
    current_review.status == "updated" && current_review.review_status == "to_be_reviewed"
  end
end
