# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class BaseController < AuthenticationController
      include PlanningApplicationAssessable
      include CommitMatchable

      before_action :set_planning_application
      before_action :ensure_planning_application_is_validated
    end
  end
end
