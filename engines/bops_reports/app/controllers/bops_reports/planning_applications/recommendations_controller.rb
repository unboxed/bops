# frozen_string_literal: true

module BopsReports
  module PlanningApplications
    class RecommendationsController < BaseController
      before_action :require_assessor_or_reviewer!, only: %i[create destroy]
      before_action :require_reviewer!, only: %i[update]
      before_action :require_assigned_user!, only: %i[create update]
      before_action :set_recommendation
      before_action :set_review_and_submit_task, if: :pre_application?

      def create
        if @planning_application.to_be_reviewed?
          @planning_application.assess!
        end

        @recommendation.update!(recommendation_params)
        @planning_application.update!(planning_application_params)
        @planning_application.submit_recommendation!

        update_task("completed")
        redirect_to redirect_with_origin || assessment_tasks_url, notice: t(".submitted")
      rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition
        redirect_to redirect_with_origin || report_url, alert: t(".submit_failed")
      end

      def update
        if @recommendation.save_and_review(review_params)
          if @recommendation.challenged?
            update_task("action_required")
            redirect_to application_url, notice: t(".challenged")
          else
            update_task("completed")
            @planning_application.determination_date = Date.current
            @planning_application.determine!
            BopsReports::SendReportEmailJob.perform_later(@planning_application.presented, current_user)

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
          update_task("in_progress")
          redirect_to assessment_tasks_url, notice: t(".withdrawn")
        else
          redirect_to report_url, alert: t(".withdrawal_not_allowed")
        end
      rescue ActiveRecord::ActiveRecordError, AASM::InvalidTransition
        redirect_to redirect_with_origin || report_url, alert: t(".withdrawal_failed")
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
        planning_application_url(@planning_application, origin: params[:origin])
      end

      def require_assessor_or_reviewer!
        unless current_user.assessor_or_reviewer?
          redirect_to redirect_with_origin || report_url, alert: t(".not_assessor_or_reviewer")
        end
      end

      def require_reviewer!
        unless current_user.reviewer?
          redirect_to redirect_with_origin || report_url, alert: t(".not_reviewer")
        end
      end

      def require_assigned_user!
        unless @planning_application.user
          redirect_to redirect_with_origin || report_url, alert: t(".not_assigned")
        end
      end

      def redirect_with_origin
        return unless params[:origin] == "review_and_submit_pre_application"

        planning_application_url(@planning_application, origin: params[:origin])
      end

      def update_task(status)
        return unless @review_and_submit_task

        @review_and_submit_task.update!(status:)
      end

      def set_review_and_submit_task
        @review_and_submit_task = @planning_application.case_record.find_task_by_slug_path!(
          "check-and-assess/complete-assessment/review-and-submit-pre-application"
        )
      rescue ActiveRecord::RecordNotFound
        Rails.logger.info("Review and submit pre-application task not found for planning application #{@planning_application.id}")
      end
    end
  end
end
