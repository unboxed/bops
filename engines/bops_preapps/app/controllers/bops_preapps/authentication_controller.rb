# frozen_string_literal: true

module BopsPreapps
  class AuthenticationController < ApplicationController
    before_action :authenticate_user!

    private

    def set_planning_application
      planning_application = current_local_authority
        .planning_applications
        .find_by!(reference: params[:reference])

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def set_task
      @task = @planning_application.case_record.find_task_by_slug_path!(params[:task_slug])
    end

    def show_sidebar
      @show_sidebar = @task.top_level_ancestor
    end

    def show_header
      @show_header_bar = true
    end
  end
end
