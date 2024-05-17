# frozen_string_literal: true

module PlanningApplications
  module Review
    class BaseController < AuthenticationController
      include PlanningApplicationAssessable
      include CommitMatchable

      before_action :set_planning_application
      before_action :ensure_planning_application_is_validated
      before_action :ensure_user_is_reviewer
    end
  end
end
