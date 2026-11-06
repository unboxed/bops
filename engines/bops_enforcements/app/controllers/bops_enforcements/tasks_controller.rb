# frozen_string_literal: true

module BopsEnforcements
  class TasksController < ApplicationController
    include BopsCore::TasksController

    def tasks_modules = [BopsEnforcements::Tasks, BopsCore::Tasks]

    before_action :set_enforcement
    before_action :set_documents
    before_action :build_form
    before_action :ensure_case_is_not_closed
    before_action :show_sidebar
    before_action :show_header

    def show
      super
    end

    def edit
      super
    end

    def update
      super
    end

    private

    def set_case_record
      @case_record = @current_local_authority.enforcements.find_by!(reference: params[:reference]).case_record
    end

    def set_enforcement
      @enforcement = EnforcementPresenter.new(@case_record.caseable, view_context)
    end

    def ensure_case_is_not_closed
      return if @enforcement.open?
      return if @enforcement.requested_closure? && current_user.reviewer?

      redirect_to bops_enforcements.enforcement_path(@enforcement), alert: t(".failure")
    end

    def show_header
      @show_header_bar = true
    end
  end
end
