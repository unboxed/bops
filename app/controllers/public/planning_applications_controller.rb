# frozen_string_literal: true

module Public
  class PlanningApplicationsController < ApplicationController
    skip_before_action :set_current_user

    before_action :set_planning_application, only: :decision_notice
    before_action :ensure_decision_is_present, only: :decision_notice

    def decision_notice
      respond_to do |format|
        format.html
      end
    end

    private

    def ensure_decision_is_present
      render plain: "Not Found", status: :not_found if @planning_application.determined_at.blank?
    end
  end
end
