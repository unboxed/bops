# frozen_string_literal: true

module PlanningApplications
  module Consultee
    class ResponsesController < AuthenticationController
      before_action :set_planning_application
      before_action :set_consultation
      before_action :set_consultees, only: %i[index]
      before_action :set_consultee, only: %i[new create edit update]
      before_action :set_consultee_response, only: %i[new create edit update]

      def index
        respond_to do |format|
          format.html
        end
      end

      def new
        respond_to do |format|
          format.html
        end
      end

      def create
        respond_to do |format|
          if @consultee_response.save
            format.html do
              redirect_to planning_application_consultees_responses_path(@planning_application), notice: t(".success")
            end
          else
            format.html { render :new }
          end
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @consultee_response.update(redaction_params, :redaction)
            format.html do
              redirect_to planning_application_consultee_path(@planning_application, @consultee), notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def consultee_id
        Integer(params[:consultee_id])
      end

      def set_consultees
        @consultees = @consultation.consultees
      end

      def set_consultee
        @consultee = @consultation.consultees.find(consultee_id)
      end

      def consultee_response_id
        Integer(params[:id])
      end

      def consultee_response_params
        params.require(:consultee_response).permit(*consultee_response_attributes)
      end

      def consultee_response_attributes
        [:name, :email, :summary_tag, :response, :redacted_response, :received_at, documents: []]
      end

      def redaction_params
        params
          .require(:consultee_response)
          .permit(:redacted_response)
          .merge(redacted_by: current_user)
      end

      def set_consultee_response
        @consultee_response = \
          case action_name
          when "new"
            @consultee.responses.new
          when "create"
            @consultee.responses.new(consultee_response_params)
          else
            @consultee.responses.find(consultee_response_id)
          end
      end
    end
  end
end
