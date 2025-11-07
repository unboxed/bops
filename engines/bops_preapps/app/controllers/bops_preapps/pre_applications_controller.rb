# frozen_string_literal: true

module BopsPreapps
  class PreApplicationsController < ApplicationController
    before_action :set_planning_application, only: %i[show]
    before_action :set_case_record, only: %i[show]
    before_action :set_grouped_tasks, only: %i[show]

    def index
      @search ||= PlanningApplicationSearch.new(params)
      respond_to do |format|
        format.html
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def set_planning_application
      @planning_application = PlanningApplication.find_by(reference: params[:id])
    end

    def set_case_record
      @case_record = @planning_application.case_record
    end

    def set_grouped_tasks
      @grouped_tasks = @case_record.tasks.group_by(&:section)
    end
  end
end
