# frozen_string_literal: true

module PlanningApplications
  class PanelsComponent < ViewComponent::Base
    def initialize(planning_applications:, exclude_others:, current_user:, search:)
      @planning_applications = planning_applications
      @exclude_others = exclude_others
      @current_user = current_user
      @search = search
    end

    private

    def panel_types
      [
        (:not_started_and_invalid unless reviewer_applications?),
        (:under_assessment unless reviewer_applications?),
        :awaiting_determination,
        (:awaiting_correction unless current_user.assessor?),
        :closed
      ].compact
    end

    def reviewer_applications?
      @reviewer_applications ||= exclude_others && current_user.reviewer?
    end

    def all_planning_applications
      search.query ? search.results : planning_applications
    end

    attr_reader :planning_applications, :exclude_others, :current_user, :search
  end
end
