# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module PolicyAreas
      class PolicyClassesController < BaseController
        before_action :find_planning_application_policy_class, only: %i[destroy]
        before_action :ensure_planning_application_is_not_preapp

        def destroy
          respond_to do |format|
            format.html do
              if @planning_application_policy_class.destroy
                redirect_to redirect_path, notice: t(".success")
              else
                redirect_to redirect_path, notice: t(".failure")
              end
            end
          end
        end

        private

        def redirect_path
          params[:redirect_to].presence || planning_application_assessment_path(@planning_application)
        end

        def find_planning_application_policy_class
          @planning_application_policy_class = @planning_application.planning_application_policy_classes.find(params[:id])
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
