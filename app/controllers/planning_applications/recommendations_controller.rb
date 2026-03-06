# frozen_string_literal: true

module PlanningApplications
  class RecommendationsController < AuthenticationController
    before_action :set_planning_application
    before_action :ensure_planning_application_is_not_preapp
    before_action :ensure_no_open_post_validation_requests, only: %i[update]

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

    def submit
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
          format.html {
            redirect_to submit_recommendation_planning_application_path(@planning_application),
              alert: t(".failure")
          }
        end
      end
    end

    def destroy
      respond_to do |format|
        if @planning_application.may_withdraw_recommendation?
          @planning_application.withdraw_last_recommendation!

          format.html do
            redirect_to submit_planning_application_recommendation_path(@planning_application),
              notice: t(".success")
          end
        else
          format.html {
            redirect_to planning_application_recommendation_path(@planning_application),
              alert: t(".failure")
          }
        end
      end
    end

    private

    def ensure_no_open_post_validation_requests
      return if @planning_application.no_open_post_validation_requests_excluding_time_extension?

      flash.now[:alert] = t(".has_open_non_validation_requests_html", href: post_validation_requests_planning_application_validation_validation_requests_path(@planning_application))
      render :submit and return
    end
  end
end
