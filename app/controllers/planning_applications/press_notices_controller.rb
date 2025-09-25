# frozen_string_literal: true

module PlanningApplications
  class PressNoticesController < AuthenticationController
    include PublicityPermittable

    before_action :set_planning_application
    before_action :redirect_to_application_page, unless: :public_or_preapp?

    before_action :ensure_publicity_is_permitted
    before_action :build_press_notice, only: [:new, :create]
    before_action :set_press_notice, only: [:show, :update]
    before_action :redirect_to_reference_url, only: %i[new show]

    def new
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
      @press_notice.assign_attributes(press_notice_params)

      respond_to do |format|
        if @press_notice.save
          enqueue_send_press_notice_email_job

          format.html do
            redirect_to planning_application_consultation_path(@planning_application), notice: t(".success")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
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

    private

    def press_notice_params
      params.require(:press_notice).permit(:required, :other_reason, reasons: [])
    end

    def build_press_notice
      @press_notice = @planning_application.press_notices.new
    end

    def set_press_notice
      @press_notice = @planning_application.press_notice || build_press_notice
    end

    def enqueue_send_press_notice_email_job
      SendPressNoticeEmailJob.perform_later(@press_notice, current_user)
    end

    def redirect_to_application_page
      redirect_to make_public_planning_application_path(@planning_application), alert: t(".make_public")
    end

    def public_or_preapp?
      @planning_application.make_public? || @planning_application.pre_application?
    end
  end
end
