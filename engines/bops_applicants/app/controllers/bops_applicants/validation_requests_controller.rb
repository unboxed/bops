# frozen_string_literal: true

module BopsApplicants
  class ValidationRequestsController < ApplicationController
    before_action :set_planning_application
    before_action :require_change_access_id!
    before_action :set_validation_requests
    before_action :set_validation_request, only: %i[show edit update]
    before_action :set_applicant_responding, only: %i[update]

    def index
      respond_to do |format|
        format.html
      end
    end

    def show
      respond_to do |format|
        if @validation_request.closed? || @validation_request.cancelled?
          format.html
        else
          format.html do
            raise BopsCore::Errors::NotFoundError, "Validation request is not in the correct state"
          end
        end
      end
    end

    def edit
      respond_to do |format|
        if @validation_request.open?
          format.html
        else
          format.html do
            raise BopsCore::Errors::NotFoundError, "Validation request is not in the correct state"
          end
        end
      end
    end

    def update
      respond_to do |format|
        if update_validation_request
          format.html { redirect_to validation_requests_url(access_control_params), notice: t(".success") }
        else
          format.html { render :edit, alert: t(".failure_html", feedback_email: current_local_authority.feedback_email) }
        end
      end
    end

    private

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_reference
      params[:planning_application_reference]
    end

    def planning_application_id
      params[:planning_application_id]
    end

    def planning_application_param
      planning_application_reference || planning_application_id
    end

    def set_validation_requests
      @validation_requests = @planning_application.validation_requests.grouped_by_type
    end

    def validation_request_id
      Integer(params.fetch(:id))
    end

    def set_applicant_responding
      @validation_request.applicant_responding = true
    end

    def transaction(&)
      ActiveRecord::Base.transaction(&)
    end
  end
end
