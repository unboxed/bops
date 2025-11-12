# frozen_string_literal: true

module BopsEnforcements
  class EnforcementsController < ApplicationController
    before_action :set_enforcements, only: %i[index]
    before_action :set_enforcement, only: %i[show]
    before_action :set_case_record, only: %i[show]
    before_action :set_grouped_tasks, only: %i[show]

    def index
      @show_section_navigation = true
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

    def set_enforcements
      @enforcements = current_local_authority
        .enforcements
        .joins(:case_record)
        .by_received_at_desc

      if params["urgent"]
        @enforcements = @enforcements.where(urgent: true)
      end
    end

    def set_enforcement
      @enforcement = current_local_authority
        .enforcements
        .joins(:case_record)
        .find_by!(case_record: {id: params[:id]})
    end

    def filter_params
      params.permit(:urgent)
    end

    def set_case_record
      @case_record = @enforcement.case_record
    end

    def set_grouped_tasks
      @grouped_tasks = @case_record.tasks.group_by(&:section)
    end
  end
end
