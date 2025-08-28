# frozen_string_literal: true

class ConsiderationSet < ApplicationRecord
  belongs_to :planning_application
  alias_method :parent_record, :planning_application

  with_options dependent: :destroy do
    has_many :considerations, -> { order(position: :asc) }
    has_many :reviews, -> { order(created_at: :desc) }, as: :owner
  end

  def current_review
    reviews.load.first || reviews.create!
  end

  def update_review(params)
    case params[:status]
    when "complete"
      mark_as_complete(params)
    when "in_progress"
      mark_as_in_progress(params)
    else
      raise ArgumentError, "Unexpected review status: #{params[:status].inspect}"
    end
  end

  def suggested_outcome
    return "does_not_comply" if considerations.exists?(summary_tag: "does_not_comply")
    return "needs_changes" if considerations.exists?(summary_tag: "needs_changes")

    "complies"
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
end
