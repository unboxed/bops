# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class MeetingsController < AuthenticationController
      include ReturnToReport

      before_action :set_planning_application
      before_action :build_meeting, only: %i[new create index]
      before_action :store_return_to_report_path, only: [:index]

      def index
        @meetings = @planning_application.meetings.by_occurred_at_desc.includes(:created_by)
        respond_to do |format|
          format.html
        end
      end

      def show
        respond_to do |format|
          format.html
        end
      end

      def new
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
            format.html { render :new }
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

      def redirect_path
        report_path_or(planning_application_assessment_tasks_path(@planning_application))
      end
    end
  end
end
