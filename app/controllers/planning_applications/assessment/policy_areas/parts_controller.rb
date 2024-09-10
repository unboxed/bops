# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module PolicyAreas
      class PartsController < BaseController
        before_action :ensure_can_assess_planning_application
        before_action :find_policy_parts

        def index
          respond_to do |format|
            format.html
          end
        end

        private

        def find_policy_parts
          @policy_parts = PolicySchedule.schedule_2.policy_parts
        end
      end
    end
  end
end
