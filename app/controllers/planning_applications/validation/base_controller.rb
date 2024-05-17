# frozen_string_literal: true

module PlanningApplications
  module Validation
    class BaseController < AuthenticationController
      before_action :set_planning_application
    end
  end
end
