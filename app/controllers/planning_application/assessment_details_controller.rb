# frozen_string_literal: true

class PlanningApplication
  class AssessmentDetailsController < AuthenticationController
    include CommitMatchable
    include PlanningApplicationAssessable

    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated
    before_action :set_assessment_detail, only: %i[show edit update]
    before_action :set_category, :set_rejected_assessment_detail, only: %i[new create]

    def new
      @assessment_detail = @planning_application.assessment_details.new

      respond_to do |format|
        format.html
      end
    end

    def create
      @assessment_detail = @planning_application.assessment_details.new(assessment_details_params).tap do |record|
        record.reviewer_verdict = :updated if @rejected_assessment_detail.present?
      end

      respond_to do |format|
        if @assessment_detail.save
          format.html do
            redirect_to(
              planning_application_assessment_tasks_path(@planning_application),
              notice: created_notice
            )
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

    def set_category
      @category = params[:category] || assessment_details_params[:category]
    end

    def set_rejected_assessment_detail
      @rejected_assessment_detail = @planning_application.rejected_assessment_detail(category: @category)
    end

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
        .merge(assessment_status: assessment_status, user: current_user)
    end

    def assessment_status
      save_progress? ? :in_progress : :complete
    end

    def created_notice
      action = @rejected_assessment_detail.present? ? :updated : :created
      I18n.t("assessment_details.#{@category}_successfully_#{action}")
    end
  end
end
