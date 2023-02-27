# frozen_string_literal: true

module PlanningApplications
  class PanelsComponent < ViewComponent::Base
    def initialize(planning_applications:, exclude_others:, current_user:, search:, filter:)
      @planning_applications = planning_applications
      @exclude_others = exclude_others
      @current_user = current_user
      @search = search
      @filter = filter
    end

    private

    def panel_types
      [].compact
    end

    def reviewer_applications?
      @reviewer_applications ||= exclude_others && current_user.reviewer?
    end

    def all_planning_applications
      if search.query
        search.results
      elsif filter.filter_options
        filter.results
      else
        planning_applications
      end
    end

    attr_reader :planning_applications, :exclude_others, :current_user, :search, :filter
  end
end
