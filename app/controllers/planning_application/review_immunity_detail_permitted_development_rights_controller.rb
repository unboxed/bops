# frozen_string_literal: true

class PlanningApplication
  class ReviewImmunityDetailPermittedDevelopmentRightsController < AuthenticationController
    include PlanningApplicationAssessable
    include PermittedDevelopmentRights
    include CommitMatchable

    rescue_from ReviewImmunityDetail::NotCreatableError, with: :redirect_failed_create_error

    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated
    before_action :ensure_planning_application_is_possibly_immune
    before_action :set_permitted_development_right, only: %i[show edit update]
    before_action :set_permitted_development_rights, only: %i[new show edit]
    before_action :set_review_immunity_details, only: %i[new show edit]
    before_action :set_review_immunity_detail, only: %i[show edit update]
    before_action :ensure_review_immunity_detail_is_editable, only: %i[edit update]
    before_action :set_evidence_group_presenters

    def show
      respond_to do |format|
        format.html
      end
    end

    def new
      @permitted_development_right = @planning_application.permitted_development_rights.new
      @review_immunity_detail = @planning_application.immunity_detail.review_immunity_details.new

      @form = ReviewImmunityDetailPermittedDevelopmentRightForm.new(
        planning_application: @planning_application
      )

      respond_to do |format|
        format.html
      end
    end

    def edit
      @form = ReviewImmunityDetailPermittedDevelopmentRightForm.new(
        planning_application: @planning_application
      )

      respond_to do |format|
        format.html
      end
    end

    def create
      @form = ReviewImmunityDetailPermittedDevelopmentRightForm.new(
        planning_application: @planning_application,
        params: review_immunity_detail_permitted_development_right_form_params
      )

      if @form.save
        redirect_to planning_application_assessment_tasks_path(@planning_application),
                    notice: I18n.t("review_immunity_detail_permitted_development_rights.successfully_created")
      else
        set_permitted_development_rights
        set_review_immunity_details
        render :new
      end
    end

    def update
      @form = ReviewImmunityDetailPermittedDevelopmentRightForm.new(
        planning_application: @planning_application,
        params: review_immunity_detail_permitted_development_right_form_params,
        review_immunity_detail: @review_immunity_detail,
        permitted_development_right: @permitted_development_right
      )

      if @form.update
        redirect_to planning_application_assessment_tasks_path(@planning_application),
                    notice: I18n.t("review_immunity_detail_permitted_development_rights.successfully_updated")
      else
        set_permitted_development_rights
        set_review_immunity_details
        render :edit
      end
    end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def review_immunity_detail_permitted_development_right_form_params
      params.require(:review_immunity_detail_permitted_development_right_form).permit(
        review_immunity_detail: %i[decision decision_reason yes_decision_reason no_decision_reason decision_type
                                   summary],
        permitted_development_right: %i[removed removed_reason]
      ).merge(review_immunity_detail_status:, permitted_development_right_status:)
    end

    def ensure_planning_application_is_possibly_immune
      return if @planning_application.possibly_immune?

      render plain: "forbidden", status: :forbidden
    end

    def ensure_review_immunity_detail_is_editable
      return unless @review_immunity_detail.accepted?

      render plain: "forbidden", status: :forbidden
    end

    def set_review_immunity_details
      @review_immunity_details = @planning_application.immunity_detail.review_immunity_details.reviewer_not_accepted
    end

    def set_review_immunity_detail
      @review_immunity_detail = @planning_application.immunity_detail.current_review_immunity_detail
    end

    def review_immunity_detail_status
      save_progress? ? "in_progress" : "complete"
    end

    def permitted_development_right_status
      return "in_progress" if save_progress?

      case params.dig(:review_immunity_detail_permitted_development_right_form, :permitted_development_right, :removed)
      when "true"
        "removed"
      when "false"
        "checked"
      end
    end

    def redirect_failed_create_error(error)
      redirect_to planning_application_assessment_tasks_path(@planning_application), alert: error.message
    end

    def set_evidence_group_presenters
      return unless @planning_application.possibly_immune?

      @evidence_groups = @planning_application.immunity_detail.evidence_groups.map do |group|
        EvidenceGroupPresenter.new(view_context, group)
      end
    end
  end
end
