# frozen_string_literal: true

class PlanningApplication
  class AssessmentDetailsController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated
    before_action :set_assessment_detail, only: %i[show edit update]

    def new
      @assessment_detail = @planning_application.assessment_details.new
      @category = params[:category]

      respond_to do |format|
        format.html
      end
    end

    def create
      @assessment_detail = @planning_application.assessment_details.new(assessment_details_params).tap do |record|
        record.user = current_user
        record.status = status
      end

      respond_to do |format|
        if @assessment_detail.save
          format.html do
            redirect_to planning_application_assessment_tasks_path(@planning_application),
                        notice: I18n.t("assessment_details.#{@assessment_detail.category}_successfully_created")
          end
        else
          @category = @assessment_detail.category
          format.html { render :new }
        end
      end
    end

    def show
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
      @assessment_detail.assign_attributes(user: current_user, status: status)

      respond_to do |format|
        if @assessment_detail.update(assessment_details_params)
          format.html do
            redirect_to planning_application_assessment_tasks_path(@planning_application),
                        notice: I18n.t("assessment_details.#{@assessment_detail.category}_successfully_updated")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def set_planning_application
      @planning_application = planning_applications_scope.find(planning_application_id)
    end

    def set_assessment_detail
      @assessment_detail = @planning_application.assessment_details.find(assessment_detail_id)
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def assessment_detail_id
      Integer(params[:id])
    end

    def assessment_details_params
      params
        .require(:assessment_detail)
        .permit(:entry, :category, :additional_information)
    end

    def save_progress?
      params[:commit] == I18n.t("form_actions.save_and_come_back_later")
    end

    def status
      save_progress? ? "in_progress" : "completed"
    end

    def ensure_planning_application_is_validated
      return if @planning_application.validated?

      render plain: "forbidden", status: :forbidden
    end
  end
end
