# frozen_string_literal: true

module PlanningApplications
  class TabsComponent < ViewComponent::Base
    def initialize(planning_applications:, exclude_others:, current_user:, search_filter:, local_authority:)
      @planning_applications = planning_applications
      @exclude_others = exclude_others
      @current_user = current_user
      @search_filter = search_filter
      @local_authority = local_authority
    end

    private

    def tab_types
      [:closed]
    end

    def reviewer_applications?
      @reviewer_applications ||= exclude_others && current_user.reviewer?
    end

    def all_planning_applications
      if search_filter.results
        if @exclude_others
          search_filter.results.includes([:user]).select { |pa| pa.user == @current_user || pa.user.nil? }
        else
          search_filter.results.includes([:user])
        end
      else
        planning_applications
      end
    end

    def local_authority_most_recent_audits_for_planning_applications
      local_authority.audits.most_recent_for_planning_applications
    end

    attr_reader :planning_applications, :exclude_others, :current_user, :search_filter, :local_authority
  end
end
