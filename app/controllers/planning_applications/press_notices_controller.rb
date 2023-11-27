# frozen_string_literal: true

module PlanningApplications
  class PressNoticesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_press_notice

    def show
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @press_notice.update(press_notice_params)
          enqueue_send_press_notice_email_job

          format.html do
            redirect_to planning_application_consultation_path(@planning_application), notice: t(".success")
          end
        else
          format.html { render :show }
        end
      end
    end

    alias_method :update, :create

    private

    def press_notice_params
      params.require(:press_notice).permit(:required, :other_reason, reasons: [])
    end

    def set_press_notice
      @press_notice = @planning_application.press_notice || @planning_application.build_press_notice
    end

    def enqueue_send_press_notice_email_job
      SendPressNoticeEmailJob.perform_later(@press_notice, current_user)
    end
  end
end
