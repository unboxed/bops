# frozen_string_literal: true

module PlanningApplications
  module Review
    module PolicyAreas
      class PolicyClassesController < BaseController
        before_action :find_planning_application_policy_class, only: %i[show edit update]
        before_action :build_form, only: %i[edit update]
        before_action :set_review, only: %i[show edit update]
        before_action :set_policy_sections, only: %i[edit update]
        before_action :set_task, only: %i[update]

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
            reset_assessment_tasks! if return_to_officer?

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
          params.require(:review)
            .permit(:review_status, :action, :comment)
            .merge(reviewer: current_user, reviewed_at: Time.current, status: assessment_status)
        end

        def set_review
          @review = @planning_application_policy_class.current_review
        end

        def set_policy_sections
          @policy_sections = @planning_application_policy_class.planning_application_policy_sections.group_by { |section| section.title }.in_order_of(:first, PolicySection::TITLES)
        end

        def set_task
          @task = @planning_application.case_record.find_task_by_slug_path("check-and-assess/assess-against-legislation/assess-against-legislation")
        end

        def return_to_officer?
          params.dig(:review, :action) == "rejected"
        end
      end
    end
  end
end
