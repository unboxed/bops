# frozen_string_literal: true

module BopsPreapps
  class ConsulteesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_task
    before_action :set_constraint
    before_action :set_consultation
    before_action :show_sidebar
    before_action :show_header

    def new
      @consultees = @consultation.consultees
    end

    def create
      if @constraint.update(consultee_params)
        redirect_to route_for(:task, @planning_application, @task),
          notice: t(".success")
      else
        @consultees = @consultation.consultees
        render :new, status: :unprocessable_content
      end
    end

    private

    def set_constraint
      constraint_id = params[:constraint_id] || params.dig(:planning_application_constraint, :constraint)
      @constraint = @planning_application.planning_application_constraints.find(constraint_id)
    end

    def set_consultation
      @consultation = @planning_application.consultation
    end

    def consultee_params
      params.require(:planning_application_constraint).permit(:consultation_required, consultee_ids: [])
    end
  end
end
