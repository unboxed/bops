# frozen_string_literal: true

module BopsEnforcements
  class EnforcementsController < ApplicationController
    class_attribute :active_page_key, instance_writer: false, default: "enforcements"

    before_action :set_enforcements, except: %i[show]
    before_action :set_enforcement, only: %i[show]
    before_action :set_case_record, only: %i[show]
    before_action :set_grouped_tasks, only: %i[show]

    def index
      @show_section_navigation = true
      respond_to do |format|
        format.html { render :index }
      end
    end

    alias_method :unassigned, :index
    alias_method :closed, :index
    alias_method :updated, :index
    alias_method :all, :index

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

      case action_name
      when "index"
        @enforcements = @enforcements.where(case_record: {user: current_user})
      when "unassigned"
        @enforcements = @enforcements.where(case_record: {user: nil})
      when "closed"
        @attributes = %i[to_param to_s days_status_tag urgent]
        @enforcements = @enforcements.where(status: :closed)
      when "all"
        @attributes = %i[to_param to_s days_status_tag user_name urgent status_tag]
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
      @grouped_tasks = @case_record.tasks.visible.group_by(&:section)
    end
  end
end
