# frozen_string_literal: true

module PlanningApplications
  module Consultation
    class ResponsesController < AuthenticationController
      class << self
        private

        def local_prefixes
          [controller_path, "bops_core/tasks"]
        end
      end

      before_action :set_planning_application
      before_action :set_task
      before_action :set_consultation
      before_action :set_consultee
      before_action :set_consultee_response, only: %i[new create edit update]
      before_action :show_sidebar

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
            format.html { redirect_to @task.url, notice: t(".success") }
          else
            format.html { render :new, status: :unprocessable_content }
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
            format.html { redirect_to @task.url, notice: t(".success") }
          else
            format.html { render :edit, status: :unprocessable_content }
          end
        end
      end

      private

      def set_task
        @task = @planning_application.case_record.find_task_by_slug_path!(params[:task_slug])
      end

      def set_consultee
        @consultee = @consultation.consultees.find(consultee_id)
      end

      def consultee_id
        Integer(params[:consultee_id])
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid consultee id: #{params[:consultee_id].inspect}"
      end

      def consultee_response_id
        Integer(params[:id])
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid consultee response id: #{params[:id].inspect}"
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
        @consultee_response =
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
