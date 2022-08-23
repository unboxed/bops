# frozen_string_literal: true

class RecommendationsController < AuthenticationController
  before_action :set_planning_application

  def new
    @recommendation = RecommendationForm.new(
      recommendation: @planning_application.existing_or_new_recommendation
    )
  end

  def create
    @recommendation = RecommendationForm.new(
      recommendation: @planning_application.pending_or_new_recommendation,
      **recommendation_form_params
    )

    if @recommendation.save
      redirect_to(@planning_application)
    else
      render :new
    end
  end

  private

  def recommendation_form_params
    params
      .require(:recommendation_form)
      .permit(:decision, :public_comment, :assessor_comment)
      .merge(assessor: current_user, save_progress: save_progress?)
  end

  def save_progress?
    params[:commit]&.downcase&.match(/save/).present?
  end
end
