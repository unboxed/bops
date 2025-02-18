# frozen_string_literal: true

module PlanningApplications
  module Review
    module PolicyAreas
      class PolicyClassesController < BaseController
        before_action :find_planning_application_policy_class, only: %i[show edit update]
        before_action :build_form, only: %i[edit update]
        before_action :set_review, only: %i[show edit update]

        def index
          respond_to do |format|
            format.html
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
          @form.update(policy_section_status_params)

          if @planning_application_policy_class.update_review(review_params)
            redirect_to planning_application_review_policy_areas_policy_classes_path(@planning_application, anchor: "review-policy-classes"), notice: t(".success")
          else
            render :edit
          end
        end

        private

        def find_planning_application_policy_class
          @planning_application_policy_class = @planning_application.planning_application_policy_classes.find(params[:id])
        end

        def policy_section_status_params
          params.require(:planning_application_policy_sections).permit(
            params[:planning_application_policy_sections].keys.map do |key|
              [key, [:status, {comments_attributes: [:id, :text]}]]
            end.to_h
          )
        end

        def build_form
          @form = PolicySectionForm.new(
            planning_application: @planning_application,
            policy_class: @planning_application_policy_class.policy_class
          )
        end

        def review_params
          params.require(:review).permit(:review_status, :action, :comment).merge(reviewer: current_user, reviewed_at: Time.current)
        end

        def set_review
          @review = @planning_application_policy_class.current_review
        end
      end
    end
  end
end
