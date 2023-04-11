# frozen_string_literal: true

class PlanningApplication
  class ImmunityDetailsController < AuthenticationController
    include CommitMatchable
    include PlanningApplicationAssessable

    before_action :set_planning_application
    before_action :set_immunity_detail
    before_action :ensure_planning_application_is_validated

    def new
      @groups = @planning_application.proposal_details.select do |proposal_detail|
        proposal_detail.portal_name == "immunity-check"
      end

      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        format.html do
          redirect_to planning_application_assessment_tasks_path(@planning_application),
                      notice: I18n.t("assessment_details.immunity_detail_successfully_updated")
        end
      end
    end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def set_immunity_detail
      @immunity_detail = @planning_application.immunity_detail
    end

    def planning_applications_scope
      current_local_authority.planning_applications.includes(:permitted_development_rights)
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end
  end
end
