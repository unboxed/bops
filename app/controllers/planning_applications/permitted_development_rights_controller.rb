# frozen_string_literal: true

module PlanningApplications
  class PermittedDevelopmentRightsController < AuthenticationController
    include CommitMatchable
    include PlanningApplicationAssessable
    include PermittedDevelopmentRights

    rescue_from PermittedDevelopmentRight::NotCreatableError, with: :redirect_failed_create_error

    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated
    before_action :set_permitted_development_right, only: %i[show edit update]
    before_action :set_permitted_development_rights, only: %i[new show edit]
    before_action :ensure_permitted_development_right_is_editable, only: %i[edit update]

    def show
      respond_to do |format|
        format.html
      end
    end

    def new
      @permitted_development_right = @planning_application.permitted_development_rights.new

      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      @permitted_development_right = @planning_application.permitted_development_rights.new(
        permitted_development_right_params
      ).tap do |record|
        record.status = status
        record.assessor = current_user
      end

      if @permitted_development_right.save
        redirect_to planning_application_assessment_tasks_path(@planning_application),
          notice: I18n.t("permitted_development_rights.successfully_created")
      else
        set_permitted_development_rights
        render :new
      end
    end

    def update
      @permitted_development_right.assign_attributes(status:, assessor: current_user)

      respond_to do |format|
        if @permitted_development_right.update(permitted_development_right_params)
          format.html do
            redirect_to planning_application_assessment_tasks_path(@planning_application),
              notice: I18n.t("permitted_development_rights.successfully_updated")
          end
        else
          set_permitted_development_rights
          format.html { render :edit }
        end
      end
    end

    private

    def permitted_development_right_params
      params.require(:permitted_development_right).permit(:removed, :removed_reason)
    end

    def status
      return "in_progress" if save_progress?

      case permitted_development_right_params[:removed]
      when "true"
        "removed"
      when "false"
        "checked"
      else
        raise ArgumentError, "#{permitted_development_right_params[:removed]} is not a valid status"
      end
    end

    def ensure_permitted_development_right_is_editable
      return unless @permitted_development_right.accepted? || @permitted_development_right.to_be_reviewed?

      render plain: "forbidden", status: :forbidden
    end

    def redirect_failed_create_error(error)
      redirect_to planning_application_assessment_tasks_path(@planning_application), alert: error.message
    end
  end
end
