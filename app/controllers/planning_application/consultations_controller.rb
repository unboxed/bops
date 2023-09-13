# frozen_string_literal: true

class PlanningApplication
  class ConsultationsController < AuthenticationController
    include ActionView::Helpers::SanitizeHelper
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_consultation

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def set_consultation
      @consultation = @planning_application.consultation
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end
  end
end
