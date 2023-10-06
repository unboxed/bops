# frozen_string_literal: true

module PlanningApplications
  class NeighbourResponsesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
    before_action :set_neighbour_responses, except: %i[edit update]
    before_action :set_neighbour_response, only: %i[edit update]

    def index; end

    def new
      @neighbour_response = @consultation.neighbour_responses.new
    end

    def edit; end

    def create
      @neighbour_response = @consultation.neighbour_responses
                                         .build(neighbour_response_params.except(:address, :new_address, :files))

      @neighbour_response.neighbour = find_neighbour

      create_files(@neighbour_response) if neighbour_response_params[:files].compact_blank.any?

      if @neighbour_response.save
        respond_to do |format|
          format.html do
            redirect_to planning_application_consultation_neighbour_responses_path(@planning_application, @consultation)
          end
          create_audit_log(@neighbour_response, "uploaded")
        end
      else
        render :new
      end
    end

    def update
      if @neighbour_response.update(neighbour_response_params.except(:address, :files))
        if neighbour_response_params.key?(:address)
          @neighbour_response.neighbour.update(address: neighbour_response_params[:address])
        end

        create_files(@neighbour_response) if neighbour_response_params[:files].compact_blank.any?

        respond_to do |format|
          format.html do
            redirect_to planning_application_consultation_neighbour_responses_path(@planning_application,
                                                                                   @consultation)
          end
          create_audit_log(@neighbour_response, "edited")
        end
      else
        render :edit
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

    def create_files(response)
      neighbour_response_params[:files].compact_blank.each do |file|
        @planning_application.documents.create!(file:, neighbour_response: response)
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

    def set_neighbour_response
      @neighbour_response = @consultation.neighbour_responses.find(Integer(params[:id]))
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def neighbour_response_params
      params.require(:neighbour_response).permit(
        :address, :name, :email, :received_at, :response, :new_address, :summary_tag,
        :redacted_response, tags: [], files: []
      )
    end

    def create_audit_log(_neighbour_response, action)
      Audit.create!(
        planning_application_id:,
        user: Current.user,
        activity_type: "neighbour_response_#{action}",
        audit_comment: "Neighbour response from #{@neighbour_response.neighbour.address} was #{action}"
      )
    end
  end
end
