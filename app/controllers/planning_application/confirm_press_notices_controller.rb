# frozen_string_literal: true

class PlanningApplication
  class ConfirmPressNoticesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_press_notice, only: %i[edit update]
    before_action :ensure_press_notice_is_editable, only: %i[edit update]

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if @press_notice.update(press_notice_params)
          format.html do
            redirect_to planning_application_consultations_path(@planning_application), notice: t(".success")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def press_notice_params
      params.require(:press_notice).permit(
        :press_sent_at,
        :published_at,
        :comment
      ).merge(documents_attributes:)
    end

    def documents_attributes
      files = params.dig(:press_notice, :documents_attributes, "0", :files).compact_blank
      files.map.with_index do |file, i|
        [i.to_s, { file:, planning_application_id: @planning_application.id, tags: ["Press Notice"] }]
      end.to_h
    end

    def set_press_notice
      @press_notice = @planning_application.press_notice
    end

    def ensure_press_notice_is_editable
      return if @press_notice.required?

      render plain: "forbidden", status: :forbidden
    end
  end
end
