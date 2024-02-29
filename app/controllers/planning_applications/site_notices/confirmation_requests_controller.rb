# frozen_string_literal: true

module PlanningApplications
  module SiteNotices
    class ConfirmationRequestsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_site_notice
      before_action :set_assessment_detail, if: :assessment_detail_id?

      def create
        respond_to do |format|
          SendSiteNoticeConfirmationRequestJob.perform_later(@site_notice, current_user)

          format.html do
            redirect_to return_path, notice: t(".success")
          end
        end
      end

      private

      def set_site_notice
        @site_notice = @planning_application.site_notices.find(site_notice_id)
      end

      def set_assessment_detail
        @assessment_detail = @planning_application.assessment_details.find(assessment_detail_id)
      end

      def site_notice_id
        Integer(params[:site_notice_id])
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid site notice id: #{params[:site_notice_id]}"
      end

      def assessment_detail_id?
        params.key?(:assessment_detail_id)
      end

      def assessment_detail_id
        Integer(params[:assessment_detail_id])
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid assessment detail id: #{params[:assessment_detail_id]}"
      end

      def return_path
        if assessment_detail_id?
          edit_planning_application_assessment_assessment_detail_path(@planning_application, @assessment_detail, category: "check_publicity")
        else
          new_planning_application_assessment_assessment_detail_path(@planning_application, category: "check_publicity")
        end
      end
    end
  end
end
