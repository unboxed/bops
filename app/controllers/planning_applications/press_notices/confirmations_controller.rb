# frozen_string_literal: true

module PlanningApplications
  module PressNotices
    class ConfirmationsController < AuthenticationController
      include PublicityPermittable

      before_action :set_planning_application
      before_action :ensure_publicity_is_permitted
      before_action :set_press_notice
      before_action :set_press_notices, only: :show

      def show
        respond_to do |format|
          format.html
        end
      end

      def edit
        @press_notice.published_at ||= Time.zone.today

        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @press_notice.update(press_notice_params, :confirmation)
            format.html do
              redirect_to planning_application_consultation_path(@planning_application), notice: t(".success")
            end
          else
            set_press_notices
            format.html { render :edit }
          end
        end
      end

      private

      def press_notice_params
        params.require(:press_notice).permit(:published_at, :comment, documents: [])
      end

      def set_press_notice
        @press_notice = @planning_application.press_notice

        if @press_notice.nil?
          redirect_to planning_application_press_notice_path(@planning_application), alert: t(".not_found")
        elsif !@press_notice.required?
          redirect_to planning_application_consultation_path(@planning_application), alert: t(".not_required")
        end
      end

      def set_press_notices
        @press_notices = @planning_application.press_notices.published.exclude_by_id(@press_notice.id)
      end
    end
  end
end
