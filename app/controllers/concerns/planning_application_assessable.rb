# frozen_string_literal: true

module PlanningApplicationAssessable
  extend ActiveSupport::Concern

  def ensure_planning_application_is_validated
    return if @planning_application.validated?

    render plain: "forbidden", status: :forbidden
  end
end
