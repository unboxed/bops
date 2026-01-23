# frozen_string_literal: true

module BopsPreapps
  class ConsulteeResponsesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_task
    before_action :set_consultation
    before_action :set_consultee
    before_action :set_consultee_response, only: %i[new create]
    before_action :show_sidebar
    before_action :show_header

    helper_method :back_to_task_path

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
          format.html { redirect_to back_to_task_path, notice: t(".success") }
        else
          format.html { render :new, status: :unprocessable_content }
        end
      end
    end

    private

    def back_to_task_path
      task_path(reference: @planning_application.reference, slug: @task.full_slug)
    end

    def set_consultation
      @consultation = @planning_application.consultation
    end

    def set_consultee
      @consultee = @consultation.consultees.find(consultee_id)
    rescue ActiveRecord::RecordNotFound
      redirect_to back_to_task_path, alert: t("bops_preapps.consultee_responses.consultee_not_found")
    end

    def consultee_id
      Integer(params[:consultee_id])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid consultee id: #{params[:consultee_id].inspect}"
    end

    def set_consultee_response
      @consultee_response =
        case action_name
        when "new"
          @consultee.responses.new
        when "create"
          @consultee.responses.new(consultee_response_params)
        end
    end

    def consultee_response_params
      params.require(:consultee_response).permit(*consultee_response_attributes)
    end

    def consultee_response_attributes
      [:name, :email, :summary_tag, :response, :redacted_response, :received_at, documents: []]
    end
  end
end
