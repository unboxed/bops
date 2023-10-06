# frozen_string_literal: true

module PlanningApplications
  class PressNoticesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_press_notice, only: %i[new show update]

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
      @press_notice = @planning_application.build_press_notice(assign_press_notice_params)

      respond_to do |format|
        if @press_notice.save
          @press_notice.send_press_notice_mail
          format.html do
            redirect_to planning_application_consultations_path(@planning_application), notice: t(".success")
          end
        else
          format.html { render :new }
        end
      end
    end

    def update
      respond_to do |format|
        if @press_notice.update(assign_press_notice_params)
          @press_notice.send_press_notice_mail
          format.html do
            redirect_to planning_application_consultations_path(@planning_application), notice: t(".success")
          end
        else
          format.html { render :show }
        end
      end
    end

    private

    def press_notice_params
      params.require(:press_notice).permit(
        :required,
        :press_sent_at,
        :published_at,
        :other_reason_selected,
        :other_reason,
        reasons: PressNotice.reason_keys + [:other]
      )
    end

    def assign_press_notice_params
      assign_params = press_notice_params.dup
      assign_params[:reasons] ||= {}

      if assign_params[:required] == "false"
        assign_params[:reasons] = {}
      elsif assign_params[:other_reason_selected] == "0"
        assign_params[:reasons].delete(:other)
      end

      assign_params.except(:other_reason_selected)
    end

    def set_press_notice
      @press_notice = @planning_application.press_notice || @planning_application.build_press_notice
    end
  end
end
