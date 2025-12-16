# frozen_string_literal: true

module PlanningApplications
  class ConsultationsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :redirect_to_application_page, unless: :public_or_preapp?
    before_action :show_sidebar

    def show
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if @consultation.update(consultation_params.merge(status: "in_progress"))
          format.html do
            redirect_to planning_application_consultation_path(@planning_application), notice: t(".success")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def show_sidebar
      @show_sidebar = if use_new_sidebar_layout?(:consultation)
        @planning_application.case_record.tasks.find_by(section: "Consultation")
      end
    end

    def consultation_params
      params.fetch(:consultation, {}).permit(:neighbour_letter_text, :resend_existing, :resend_reason, :end_date)
    end

    def redirect_to_application_page
      redirect_to make_public_planning_application_path(@planning_application), alert: t(".make_public")
    end

    def public_or_preapp?
      @planning_application.make_public? || @planning_application.pre_application?
    end
  end
end
