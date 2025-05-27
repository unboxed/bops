# frozen_string_literal: true

module BopsApplicants
  class ValidationRequestsController < ApplicationController
    before_action :set_planning_application
    before_action :require_change_access_id!
    before_action :set_validation_requests

    def index
      respond_to do |format|
        format.html
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

    def change_access_id
      params.fetch(:change_access_id) do
        raise BopsCore::Errors::NotFoundError, "Missing change access parameter"
      end
    end

    def require_change_access_id!
      if @planning_application.change_access_id != change_access_id
        raise BopsCore::Errors::NotFoundError, "Change access id does not match the planning application"
      end
    end

    def set_validation_requests
      @validation_requests = @planning_application.validation_requests.grouped_by_type
    end
  end
end
