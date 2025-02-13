# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module PolicyAreas
      class PolicyClassesController < BaseController
        before_action :ensure_can_assess_planning_application, only: %i[new create]
        before_action :find_policy_parts
        before_action :find_part, only: %i[new create]
        before_action :find_planning_application_policy_class, only: %i[edit update destroy]
        before_action :build_form, only: %i[edit update]
        before_action :set_review, only: %i[edit update]

        def new
          if @part.blank?
            redirect_to planning_application_assessment_policy_areas_parts_path(@planning_application),
              alert: t(".failure") and return
          end

          respond_to do |format|
            format.html
          end
        end

        def create
          class_ids = params[:policy_classes].compact_blank

          @part.policy_classes.where(id: class_ids).find_each do |policy_class|
            @planning_application.planning_application_policy_classes.find_or_create_by!(policy_class_id: policy_class.id)
          end

          redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
        end

        def edit
          respond_to do |format|
            format.html
          end
        end

        def update
          @form.update(policy_section_status_params)

          if @planning_application_policy_class.update_review(review_params)
            redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
          else
            render :edit
          end
        end

        def destroy
          respond_to do |format|
            format.html do
              if @planning_application_policy_class.destroy
                redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
              else
                render :edit
              end
            end
          end
        end

        private

        def find_policy_parts
          @policy_parts = PolicySchedule.schedule_2.policy_parts
        end

        def find_part
          @part = @policy_parts.find_by_number(params[:part])
        end

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
          params.require(:review).permit(:status).merge(assessor: current_user)
        end

        def set_review
          @review = @planning_application_policy_class.current_review
        end
      end
    end
  end
end
