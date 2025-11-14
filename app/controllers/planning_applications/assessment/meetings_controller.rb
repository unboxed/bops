# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class MeetingsController < AuthenticationController
      include ReturnToReport

      before_action :set_planning_application
      before_action :build_meeting, only: %i[create index]
      before_action :store_return_to_report_path, only: [:index]

      def index
        set_planning_application_meetings

        respond_to do |format|
          format.html
        end
      end

      def show
        respond_to do |format|
          format.html
        end
      end

      def create
        respond_to do |format|
          if @meeting.update(meeting_params)
            format.html do
              redirect_to redirect_path, notice: t(".success")
            end
          else
            set_planning_application_meetings
            format.html { render :index }
          end
        end
      end

      private

      def meeting_params
        params.require(:meeting)
          .permit(:occurred_at, :comment)
          .merge(created_by: current_user, status: "complete")
      end

      def build_meeting
        @meeting = @planning_application.meetings.new
      end

      def set_planning_application_meetings
        @meetings = @planning_application.meetings.by_occurred_at_desc.includes(:created_by)
      end

      def redirect_path
        params.dig(:meeting, :return_to).presence || report_path_or(planning_application_assessment_meetings_path)
      end
    end
  end
end
