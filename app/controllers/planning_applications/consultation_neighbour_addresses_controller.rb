# frozen_string_literal: true

module PlanningApplications
  class ConsultationNeighbourAddressesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation

    rescue_from Consultation::AddNeighbourAddressesError do |error|
      redirect_to planning_application_consultation_path(@planning_application, @consultation),
                  alert: "Error adding neighbour addresses with message: #{error.message}"
    end

    def create
      @consultation.add_neighbour_addresses!(params[:addresses], params[:polygon_search])

      respond_to do |format|
        format.html do
          redirect_to planning_application_consultation_path(@planning_application, @consultation),
                      notice: t(".success")
        end
      end
    end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def set_consultation
      @consultation = @planning_application.consultation || @planning_application.build_consultation
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end
  end
end
