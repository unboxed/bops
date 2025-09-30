# frozen_string_literal: true

module PlanningApplications
  class ConsultationRequirementsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :ensure_consultee_consultation_feature
    before_action :ensure_pre_application
    before_action :destroy_consultation_if_no_consultation_required, only: :update

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
        format.html do
          if @planning_application.update(consultation_requirement_params, :require_consultation)
            redirect_to planning_application_consultation_path(@planning_application), notice: t(".success")
          else
            render :edit
          end
        end
      end
    end

    private

    def consultation_requirement_params
      params.fetch(:planning_application, {}).permit(:consultation_required)
    end

    def ensure_consultee_consultation_feature
      return if @planning_application.consultee_consultation_feature?

      redirect_to planning_application_path(@planning_application), alert: t(".feature_disabled")
    end

    def ensure_pre_application
      return if @planning_application.pre_application?

      redirect_to planning_application_consultation_path(@planning_application),
        alert: t(".pre_application_only")
    end

    def set_consultation
      @consultation = @planning_application.consultation || @planning_application.create_consultation!
    end

    def destroy_consultation_if_no_consultation_required
      if params.dig(:planning_application, :consultation_required) == "false"
        @consultation.consultees.destroy_all
      end
    end
  end
end
