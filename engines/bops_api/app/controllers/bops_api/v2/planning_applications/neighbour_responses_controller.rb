# frozen_string_literal: true

module BopsApi
    module V2
        module PlanningApplications
            class NeighbourResponsesController < AuthenticatedController

    before_action :set_neighbour_responses, only: :index
    before_action :set_neighbour_response, only: %i[edit update]

    def index
    end

    def new
      @neighbour_response = @consultation.neighbour_responses.new
    end

    def edit
    end

    def create
        @planning_application = find_planning_application(params[:planning_application_id])
        @consultation = @planning_application.consultation
      
        neighbour = find_or_build_neighbour
        neighbour.save! unless neighbour.persisted?
      
        @neighbour_response = @consultation.neighbour_responses.new(
          neighbour_response_params.except(:address, :new_address, :files).merge(
            received_at: Time.current
          )
        )
        @neighbour_response.neighbour = neighbour
        @neighbour_response.redacted_by = current_user if @neighbour_response.redacted_response.present?
      
        ActiveRecord::Base.transaction do
          create_files(@neighbour_response) if files_present?
          @neighbour_response.save!
          create_audit_log(@neighbour_response, "uploaded")
        end
        respond_to do |format|
          format.json { render json: { message: "Neighbour response created successfully" }, status: :created }
        end
      
      rescue ActiveRecord::RecordInvalid
        set_error_messages
      
        respond_to do |format|
          format.json { render json: { errors: @neighbour_response.errors.full_messages }, status: :unprocessable_entity }
        end
      end
      

    def update
      ActiveRecord::Base.transaction do
        @neighbour_response.update!(neighbour_response_params.except(:address, :files, :response))
        @neighbour_response.neighbour.update!(address: neighbour_response_params[:address]) if address_param_present?
        create_files(@neighbour_response) if files_present?
        create_audit_log(@neighbour_response, "edited")
      end

      respond_to do |format| 
        format.html { redirect_to planning_application_consultation_neighbour_responses_path(@planning_application, @consultation), notice: t(".success") }
      end
    rescue ActiveRecord::RecordInvalid
      set_error_messages
      render :edit
    end

    private

    def find_or_build_neighbour
      if neighbour_response_params[:new_address].present?
        @consultation.neighbours.build(address: neighbour_response_params[:new_address], selected: false, source: "sent_comment")
      else
        @consultation.neighbours.find_by(address: neighbour_response_params[:address])
      end
    end

    def create_files(response)
      neighbour_response_params[:files].compact_blank.each do |file|
        @planning_application.documents.create!(file:, neighbour_response: response)
      end
    end

    def set_neighbour_responses
      @neighbour_responses = @consultation.neighbour_responses.includes(
        %i[neighbour redacted_by documents]
      ).select(&:persisted?)
    end

    def neighbour_response_id
      Integer(params[:id])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid neighbour response id: #{params[:id].inspect}"
    end

    def set_neighbour_response
      @neighbour_response = @consultation.neighbour_responses.find(neighbour_response_id)
    end

    def neighbour_response_params
      params.permit(
        :address, :name, :email, :received_at, :response, :new_address, :summary_tag,
        :redacted_response, tags: [], files: []
      )
    end

    def create_audit_log(_neighbour_response, action)
      Audit.create!(
        planning_application_id: @planning_application.id,
        user: Current.user,
        activity_type: "neighbour_response_#{action}",
        audit_comment: "Neighbour response from #{@neighbour_response.neighbour.address} was #{action}"
      )
    end

    def address_param_present?
      neighbour_response_params.key?(:address)
    end

    def files_present?
      neighbour_response_params[:files]&.compact_blank&.any?
    end

    def set_error_messages
      flash.now[:alert] = @neighbour_response.neighbour.errors.full_messages.join("\n") if @neighbour_response.neighbour&.errors&.any?
    end
  end
end
end
end
  