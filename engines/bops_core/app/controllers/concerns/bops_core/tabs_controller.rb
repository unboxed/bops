# frozen_string_literal: true

module BopsCore
  module TabsController
    extend ActiveSupport::Concern

    included do
      include BopsCore::FilterParams

      before_action :set_common_state
    end

    def mine
      @planning_applications = filtered_applications.for_current_user
      respond_to do |format|
        format.html
      end
    end

    def unassigned
      @planning_applications = filtered_applications.for_null_users
      respond_to do |format|
        format.html
      end
    end

    def closed
      @planning_applications = closed_applications
      respond_to do |format|
        format.html
      end
    end

    def all_cases
      @planning_applications = filtered_applications
      respond_to do |format|
        format.html
      end
    end

    private

    def set_common_state
      @show_section_navigation = true
      @current_tab = (action_name == "all_cases") ? :all : action_name.to_sym
      @search = search
    end

    def search
      @search ||= PlanningApplicationSearch.new(params)
    end

    def filtered_applications
      raise NotImplementedError, "#{self.class.name} must implement #filtered_applications"
    end

    def closed_applications
      raise NotImplementedError, "#{self.class.name} must implement #closed_applications"
    end
  end
end
