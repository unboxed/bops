# frozen_string_literal: true

module BopsApplicants
  class SiteNoticesController < ApplicationController
    before_action :set_planning_application
    before_action :set_site_notice
    before_action :set_config

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def planning_applications_scope
      current_local_authority.planning_applications.published
    end

    def planning_application_param
      params.fetch(:planning_application_reference)
    end

    def set_site_notice
      @site_notice = @planning_application.site_notices.latest!
    end

    def set_config
      @config = current_local_authority.site_notice
    end
  end
end
