# frozen_string_literal: true

module BopsConsultees
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController
    include BopsCore::MagicLinkAuthenticatable

    before_action :require_local_authority!

    layout "application"

    private

    def planning_applications_scope
      current_local_authority.planning_applications.accepted
    end

    def set_planning_application
      param = params[planning_application_param]
      application = planning_applications_scope.find_by!(reference: param)

      @planning_application = PlanningApplicationPresenter.new(view_context, application)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def planning_application_param
      request.path_parameters.key?(:planning_application_reference) ? :planning_application_reference : :reference
    end
  end
end
