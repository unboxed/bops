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
        format.html { render :tab_panel }
      end
    end

    def unassigned
      @planning_applications = filtered_applications.for_null_users
      respond_to do |format|
        format.html { render :tab_panel }
      end
    end

    def closed
      @planning_applications = closed_applications
      respond_to do |format|
        format.html { render :tab_panel }
      end
    end

    def all_cases
      @planning_applications = filtered_applications
      respond_to do |format|
        format.html { render :tab_panel }
      end
    end

    private

    def set_common_state
      @show_section_navigation = true
      @current_tab = (action_name == "all_cases") ? :all : action_name.to_sym
      @search = search
      @panel_type = panel_type_for(@current_tab)
      @tab_route = tab_route_for(@current_tab)
      @pre_application = pre_application?
    end

    def tab_route_for(tab)
      :"#{tab}_#{active_page_key}_path"
    end

    def panel_type_for(tab)
      tab
    end

    def pre_application?
      false
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
