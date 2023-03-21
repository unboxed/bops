# frozen_string_literal: true

class AssessmentDetailsReviewsController < AuthenticationController
  include CommitMatchable

  before_action :set_planning_application
  before_action :set_assessment_detail_review

  def show; end

  def edit; end

  def update
    @assessment_details_review.attributes = assessment_details_review_params

    if @assessment_details_review.save
      redirect_to(
        planning_application_review_tasks_path(@planning_application),
        notice: I18n.t("assessment_details_reviews.saved")
      )
    else
      render :edit
    end
  end

  private

  def set_assessment_detail_review
    @assessment_details_review = AssessmentDetailsReview.new(
      planning_application: @planning_application
    )
  end

  def assessment_details_review_params
    params
      .require(:assessment_details_review)
      .permit(permitted_attributes)
      .merge(status:)
  end

  def permitted_attributes
    AssessmentDetailsReview::ASSESSMENT_DETAILS.map do |assessment_detail|
      [
        "#{assessment_detail}_reviewer_verdict",
        "#{assessment_detail}_entry",
        "#{assessment_detail}_comment_text"
      ]
    end.flatten
  end

  def status
    mark_as_complete? ? :complete : :in_progress
  end
end
