# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class MeetingsController < AuthenticationController
      before_action :set_planning_application
      before_action :build_meeting, only: %i[new create index]

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
              redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
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
    end
  end
end
