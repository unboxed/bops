# frozen_string_literal: true

module PlanningApplications
  class PanelsComponent < ViewComponent::Base
    def initialize(planning_applications:, search:, local_authority:)
      @planning_applications = planning_applications
      @search = search
      @local_authority = local_authority
    end

    private

    delegate :exclude_others?, to: :search

    attr_reader :planning_applications, :search, :local_authority

    def panel_types
      [:closed]
    end

    def all_planning_applications
      search.call || planning_applications
    end

    def closed_planning_applications
      search.current_planning_applications.closed
    end

    def local_authority_most_recent_audits_for_planning_applications
      local_authority.audits.most_recent_for_planning_applications
    end
  end
end
