# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class AssessImmunityDetailPermittedDevelopmentRightsController < BaseController
      include PermittedDevelopmentRights

      rescue_from ::Review::NotCreatableError do
        redirect_to planning_application_assessment_tasks_path(@planning_application), alert: t(".failure")
      end

      before_action :ensure_planning_application_is_not_preapp
      before_action :ensure_planning_application_is_possibly_immune
      before_action :ensure_review_immunity_detail_is_editable, only: %i[edit update]

      def show
        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application
        )

        respond_to do |format|
          format.html
        end
      end

      def new
        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application
        )

        respond_to do |format|
          format.html
        end
      end

      def create
        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application
        )
        if @form.update(form_params)
          redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
        else
          render :new
        end
      end

      def edit
        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application
        )

        respond_to do |format|
          format.html
        end
      end

      def update
        @form = AssessImmunityDetailPermittedDevelopmentRightForm.new(
          planning_application: @planning_application
        )

        if @form.update(form_params)
          redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
        else
          render :edit
        end
      end

      private

      def form_params
        params.require(:immunity_details).permit(*form_attributes)
      end

      def form_attributes
        %i[
          immunity immunity_reason other_immunity_reason summary status
          no_immunity_reason rights_removed rights_removed_reason
        ]
      end

      def ensure_planning_application_is_possibly_immune
        return if @planning_application.possibly_immune?

        raise BopsCore::Errors::ForbiddenError, "Planning application can't be immune"
      end

      def ensure_review_immunity_detail_is_editable
        immunity_detail = @planning_application.immunity_detail
        review = immunity_detail.current_enforcement_review
        return unless review.accepted?

        raise BopsCore::Errors::ForbiddenError, "Immunity details are not editable"
      end
    end
  end
end
