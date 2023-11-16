# frozen_string_literal: true

module PlanningApplications
  class NeighbourResponsesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_consultation
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
      @neighbour_response = @consultation.neighbour_responses.new(neighbour_response_params.except(:address, :new_address, :files))

      ActiveRecord::Base.transaction do
        @neighbour_response.neighbour = find_or_build_neighbour
        create_files(@neighbour_response) if files_present?
        @neighbour_response.redacted_by = current_user if @neighbour_response.redacted_response.present?

        @neighbour_response.save!
        create_audit_log(@neighbour_response, "uploaded")
      end

      respond_to do |format|
        format.html { redirect_to planning_application_consultation_neighbour_responses_path(@planning_application), notice: t(".success") }
      end
    rescue ActiveRecord::RecordInvalid
      set_error_messages

      render :new
    end

    def update
      ActiveRecord::Base.transaction do
        @neighbour_response.update!(neighbour_response_params.except(:address, :files))
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

    def set_neighbour_responses
      @neighbour_responses = @consultation.neighbour_responses.includes(
        %i[neighbour redacted_by documents]
      ).select(&:persisted?)
    end

    def set_neighbour_response
      @neighbour_response = @consultation.neighbour_responses.find(Integer(params[:id]))
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

    def address_param_present?
      neighbour_response_params.key?(:address)
    end

    def files_present?
      neighbour_response_params[:files]&.compact_blank&.any?
    end

    def set_error_messages
      flash.now[:error] = @neighbour_response.neighbour.errors.full_messages.join("\n") if @neighbour_response.neighbour&.errors&.any?
    end
  end
end
