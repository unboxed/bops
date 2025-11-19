# frozen_string_literal: true

module PlanningApplications
  class RecommendationsController < AuthenticationController
    before_action :set_planning_application
    before_action :ensure_planning_application_is_not_preapp
    before_action :ensure_no_open_post_validation_requests, only: %i[create]

    rescue_from PlanningApplication::WithdrawRecommendationError do |_exception|
      redirect_failed_withdraw_recommendation
    end

    rescue_from PlanningApplication::SubmitRecommendationError do |_exception|
      redirect_failed_submit_recommendation
    end

    def new
      respond_to do |format|
        if @planning_application.can_submit_recommendation?
          format.html { render :new }
        else
          format.html { render plain: "Not Found", status: :not_found }
        end
      end
    end

    def show
      @assessor_name = @planning_application.recommendation.assessor.name
      @recommended_date = @planning_application.recommendation.created_at.to_date.to_fs

      respond_to do |format|
        format.html { render :show }
      end
    end

    def create
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
            redirect_to new_planning_application_recommendation_path(@planning_application),
              notice: t(".success")
          end
        else
          format.html { redirect_failed_withdraw_recommendation }
        end
      end
    end

    private

    def ensure_planning_application_is_not_preapp
      return unless @planning_application.pre_application?

      redirect_to @planning_application, alert: t("planning_applications.recommendations.not_available_for_preapp")
    end

    def ensure_no_open_post_validation_requests
      return if @planning_application.no_open_post_validation_requests_excluding_time_extension?

      flash.now[:alert] = t(
        "planning_applications.recommendations.new.has_open_non_validation_requests_html",
        href: post_validation_requests_planning_application_validation_validation_requests_path(@planning_application)
      )
      render :new and return
    end

    def redirect_failed_withdraw_recommendation
      redirect_to planning_application_recommendation_path(@planning_application),
        alert: t("planning_applications.recommendations.destroy.withdraw_failure")
    end

    def redirect_failed_submit_recommendation
      redirect_to new_planning_application_recommendation_path(@planning_application),
        alert: t("planning_applications.recommendations.create.submit_failure")
    end
  end
end
