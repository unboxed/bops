# frozen_string_literal: true

class PlanningApplicationPolicyClass < ApplicationRecord
  belongs_to :planning_application
  belongs_to :policy_class

  with_options dependent: :destroy do
    has_many :reviews, -> { order(created_at: :desc) }, as: :owner
  end

  with_options on: :update do
    validates :reporting_types, presence: true
  end

  def current_review
    reviews.load.first || reviews.create!
  end

  def update_review(params)
    status = params[:status] || params[:review_status]
    case status
    when "complete"
      mark_as_complete(params)
    when "in_progress"
      mark_as_in_progress(params)
    when "review_complete", "review_in_progress"
      update_current_review(params)
    else
      raise ArgumentError, "Unexpected review status: #{status.inspect}"
    end
  end

  private

  def mark_as_complete(params)
    if current_review.to_be_reviewed?
      reviews.create!(params.merge(status: "updated"))
    else
      current_review.update!(params)
    end
  rescue ActiveRecord::ActiveRecordError
    false
  end

  def mark_as_in_progress(params)
    if current_review.to_be_reviewed?
      current_review.update!(params.except(:status))
    else
      current_review.update!(params)
    end
  rescue ActiveRecord::ActiveRecordError
    false
  end

  def update_current_review(params)
    current_review.update!(params)
  rescue ActiveRecord::ActiveRecordError
    false
  end
end
