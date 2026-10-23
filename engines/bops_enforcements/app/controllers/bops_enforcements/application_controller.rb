# frozen_string_literal: true

module BopsEnforcements
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController
    include BopsCore::Sidebar

    before_action :require_local_authority!
    before_action :authenticate_user!

    layout "application"

    def set_documents
      @documents = @case_record.documents.active.map { Enforcements::DocumentPresenter.new(it) }
    end

    def show_sidebar
      super

      @show_sidebar = false if @task.top_level_ancestor.tasks.none?
    end
  end
end
