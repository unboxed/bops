# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module PolicyAreas
      class PolicyClassesController < BaseController
        before_action :ensure_can_assess_planning_application
        before_action :find_policy_parts
        before_action :find_part, only: %i[new create]
        before_action :find_planning_application_policy_class, only: %i[edit destroy]

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
          class_ids = params[:new_policy_classes].compact_blank

          @part.new_policy_classes.where(id: class_ids).find_each do |policy_class|
            @planning_application.planning_application_policy_classes.find_or_create_by!(new_policy_class_id: policy_class.id)
          end

          redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
        end

        def edit
          respond_to do |format|
            format.html
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
      end
    end
  end
end
