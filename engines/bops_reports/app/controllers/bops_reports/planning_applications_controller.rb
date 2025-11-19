# frozen_string_literal: true

module BopsReports
  class PlanningApplicationsController < PlanningApplications::BaseController
    include BopsCore::MagicLinkAuthenticatable

    before_action :authenticate_with_sgid!, only: :show, unless: :user_signed_in?

    def show
      if show_sidebar_for_pre_application_assessment?
        @show_sidebar ||= @planning_application.case_record.tasks.find_by(section: "Assessment")
        @show_header_bar = true
      end

      respond_to do |format|
        format.html
      end
    end

    private

    def show_sidebar_for_pre_application_assessment?
      params[:origin] == "review_and_submit_pre_application"
    end
  end
end
