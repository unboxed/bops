# frozen_string_literal: true

module PlanningApplications
  module PressNotices
    class ConfirmationsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_press_notice

      def show
        respond_to do |format|
          format.html
        end
      end

      def update
        @press_notice.assign_attributes(press_notice_params)

        respond_to do |format|
          if @press_notice.save(context: :confirmation)
            format.html do
              redirect_to planning_application_consultation_path(@planning_application), notice: t(".success")
            end
          else
            format.html { render :show }
          end
        end
      end

      private

      def press_notice_params
        params.require(:press_notice).permit(:press_sent_at, :published_at, :comment, documents: [])
      end

      def set_press_notice
        @press_notice = @planning_application.press_notice

        if @press_notice.nil?
          redirect_to planning_application_press_notice_path(@planning_application), alert: t(".not_found")
        elsif !@press_notice.required?
          redirect_to planning_application_consultation_path(@planning_application), alert: t(".not_required")
        end
      end
    end
  end
end
