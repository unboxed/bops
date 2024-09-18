# frozen_string_literal: true

class PlanningApplicationPolicyClass < ApplicationRecord
  belongs_to :planning_application
  belongs_to :new_policy_class

  has_many :reviews, as: :owner, dependent: :destroy, class_name: "Review", autosave: true

  with_options on: :update do
    validates :reporting_types, presence: true
  end

  alias_method :policy_class, :new_policy_class

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
