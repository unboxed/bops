# frozen_string_literal: true

class PlanningApplication
  class NeighbourResponsesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :set_neighbour_responses

    def new
      @neighbour_response = @consultation.neighbour_responses.new
    end

    def create
      @neighbour_response = @consultation.neighbour_responses.build(neighbour_response_params.except(:address,
                                                                                                     :new_address))
      @neighbour_response.neighbour = find_neighbour

      if @neighbour_response.save
        respond_to do |format|
          format.html do
            redirect_to new_planning_application_consultation_neighbour_response_path(@planning_application,
                                                                                      @consultation)
          end
          create_audit_log(@neighbour_response)
        end
      else
        render :new
      end
    end

    private

    def find_neighbour
      if neighbour_response_params[:new_address].present?
        @consultation.neighbours.build(address: neighbour_response_params[:new_address], selected: false)
      else
        @consultation.neighbours.find_by(address: neighbour_response_params[:address])
      end
    end

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def set_consultation
      @consultation = @planning_application.consultation
    end

    def set_neighbour_responses
      @neighbour_responses = @consultation.neighbour_responses.includes([:neighbour]).select(&:persisted?)
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def neighbour_response_params
      params.require(:neighbour_response).permit(
        :address, :name, :email, :received_at, :response, :new_address, :summary_tag
      )
    end

    def create_audit_log(_neighbour_response)
      Audit.create!(
        planning_application_id:,
        user: Current.user,
        activity_type: "neighbour_response_uploaded"
      )
    end
  end
end
