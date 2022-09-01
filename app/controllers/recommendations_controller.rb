# frozen_string_literal: true

class RecommendationsController < AuthenticationController
  before_action :set_planning_application, only: %i[new create]
  before_action :set_planning_application_with_recommendations, only: %i[edit update]
  before_action :ensure_user_is_reviewer, only: %i[update edit]
  before_action :set_recommendations, only: %i[update edit]
  before_action :set_recommendation, only: :update

  rescue_from Recommendation::ReviewRecommendationError do |error|
    render_failed_edit(error)
  end

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

  def edit
    @recommendation = @recommendations.last

    respond_to do |format|
      format.html
    end
  end

  def update
    respond_to do |format|
      @recommendation.assign_attributes(recommendation_params)
      @recommendation.review!

      format.html do
        redirect_to @planning_application, notice: "Recommendation was successfully reviewed."
      end
    end
  end

  private

  def set_planning_application_with_recommendations
    planning_application = planning_applications_scope.find(planning_application_id)

    @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
  end

  def set_recommendations
    @recommendations = @planning_application.recommendations
  end

  def planning_applications_scope
    current_local_authority.planning_applications.includes(:recommendations)
  end

  def planning_application_id
    Integer(params[:planning_application_id])
  end

  def set_recommendation
    @recommendation = @planning_application.recommendations.find(recommendation_id)
  end

  def recommendation_id
    Integer(params[:id])
  end

  def recommendation_params
    params.require(:recommendation).permit(:reviewer_comment, :challenged)
  end

  def recommendation_form_params
    params
      .require(:recommendation_form)
      .permit(:decision, :public_comment, :assessor_comment)
      .merge(assessor: current_user, save_progress: save_progress?)
  end

  def save_progress?
    params[:commit]&.downcase&.match(/save/).present?
  end

  def render_failed_edit(error)
    flash.now[:alert] = error.message

    render :edit
  end
end
