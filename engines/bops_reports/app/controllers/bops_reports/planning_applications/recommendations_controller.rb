# frozen_string_literal: true

module BopsReports
  module PlanningApplications
    class RecommendationsController < BaseController
      before_action :require_assessor!, only: %i[create destroy]
      before_action :require_reviewer!, only: %i[update]
      before_action :set_recommendation

      def create
        if @planning_application.to_be_reviewed?
          @planning_application.assess!
        end

        @recommendation.update!(recommendation_params)
        @planning_application.update!(planning_application_params)
        @planning_application.submit_recommendation!

        redirect_to assessment_tasks_url, notice: t(".submitted")
      rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition
        redirect_to report_url, alert: t(".submit_failed")
      end

      def update
        if @recommendation.save_and_review(review_params)
          if @recommendation.challenged?
            redirect_to application_url, notice: t(".challenged")
          else
            @planning_application.determination_date = Date.current
            @planning_application.determine!

            redirect_to application_url, notice: t(".not_challenged")
          end
        else
          flash.now.alert = t(".review_failed_html")
          render "bops_reports/planning_applications/show"
        end
      end

      def destroy
        if @planning_application.may_withdraw_recommendation?
          @planning_application.withdraw_last_recommendation!
          redirect_to assessment_tasks_url, notice: t(".withdrawn")
        else
          redirect_to report_url, alert: t(".withdrawal_not_allowed")
        end
      rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition
        redirect_to report_url, alert: t(".withdrawal_failed")
      end

      private

      def recommendation_form_params
        params.require(:recommendation).permit(:assessor_comment)
      end

      def recommendation_params
        recommendation_form_params.merge(status: "assessment_complete", assessor: current_user)
      end

      def planning_application_params
        {decision: "granted", public_comment: "Pre-application Advice"}
      end

      def review_form_params
        params.require(:recommendation).permit(:challenged, :reviewer_comment)
      end

      def review_params
        review_form_params.merge(status: "review_complete", reviewer: current_user)
      end

      def assessment_tasks_url
        main_app.planning_application_assessment_tasks_url(@planning_application)
      end

      def application_url
        main_app.planning_application_url(@planning_application)
      end

      def report_url
        planning_application_url(@planning_application)
      end
    end
  end
end
