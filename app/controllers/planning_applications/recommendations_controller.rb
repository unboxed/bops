# frozen_string_literal: true

module PlanningApplications
  class RecommendationsController < AuthenticationController
    before_action :set_planning_application
    before_action :ensure_planning_application_is_not_preapp
    before_action :ensure_no_open_post_validation_requests, only: %i[update]

    rescue_from PlanningApplication::WithdrawRecommendationError do |_exception|
      redirect_failed_withdraw_recommendation
    end

    rescue_from PlanningApplication::SubmitRecommendationError do |_exception|
      redirect_failed_submit_recommendation
    end

    def show
      respond_to do |format|
        if @planning_application.recommendation.present?
          @assessor_name = @planning_application.recommendation.assessor.name
          @recommended_date = @planning_application.recommendation.created_at.to_date.to_fs

          format.html
        else
          format.html { redirect_to planning_application_assessment_tasks_path(@planning_application) }
        end
      end
    end

    def edit
      respond_to do |format|
        if @planning_application.can_submit_recommendation?
          format.html
        else
          format.html { render plain: "Not Found", status: :not_found }
        end
      end
    end

    def update
      respond_to do |format|
        if @planning_application.can_submit_recommendation?
          @planning_application.submit_recommendation!

          format.html do
            redirect_to @planning_application, notice: t(".success")
          end
        else
          format.html { redirect_failed_submit_recommendation }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @planning_application.may_withdraw_recommendation?
          @planning_application.withdraw_last_recommendation!

          format.html do
            redirect_to edit_planning_application_recommendation_path(@planning_application),
              notice: t(".success")
          end
        else
          format.html { redirect_failed_withdraw_recommendation }
        end
      end
    end

    private

    def ensure_no_open_post_validation_requests
      return if @planning_application.no_open_post_validation_requests_excluding_time_extension?

      flash.now[:alert] = t(".has_open_non_validation_requests_html", href: post_validation_requests_planning_application_validation_validation_requests_path(@planning_application))
      render :edit and return
    end

    def redirect_failed_withdraw_recommendation
      redirect_to planning_application_recommendation_path(@planning_application),
        alert: t("planning_applications.recommendations.destroy.failure")
    end

    def redirect_failed_submit_recommendation
      redirect_to edit_planning_application_recommendation_path(@planning_application),
        alert: t("planning_applications.recommendations.edit.failure")
    end
  end
end
