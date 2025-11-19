# frozen_string_literal: true

module PlanningApplications
  class ConsulteesController < AuthenticationController
    before_action :set_planning_application
    before_action :redirect_to_application_page, unless: :public_or_preapp?

    before_action :set_consultation
    before_action :set_consultees
    before_action :ensure_consultation_required

    def create
      @consultee = @consultees.create!(consultee_params)

      respond_to do |format|
        format.json
      end
    end

    def show
      @consultee = @consultees.find(consultee_id)

      respond_to do |format|
        format.html
      end
    end

    def index
      respond_to do |format|
        format.html
      end
    end

    def new
      @constraint = PlanningApplicationConstraint.find(constraint_id)

      respond_to do |format|
        format.html
      end
    end

    private

    def set_consultees
      @consultees = @consultation.consultees
    end

    def constraint_id
      Integer(params[:constraint])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid constraint id: #{params[:constraint].inspect}"
    end

    def consultee_id
      Integer(params[:id])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid consultee id: #{params[:id].inspect}"
    end

    def consultee_params
      params.require(:consultee).permit(*consultee_attributes)
    end

    def consultee_attributes
      %i[origin name email_address role organisation constraint]
    end

    def redirect_to_application_page
      redirect_to new_planning_application_publication_path(@planning_application), alert: t(".make_public")
    end

    def public_or_preapp?
      @planning_application.make_public? || @planning_application.pre_application?
    end

    def ensure_consultation_required
      return unless @planning_application.pre_application?
      return if @planning_application.consultation_required?

      redirect_to edit_planning_application_consultation_requirement_path(@planning_application),
        alert: t("planning_applications.consultation_requirements.required_before_tasks")
    end
  end
end
