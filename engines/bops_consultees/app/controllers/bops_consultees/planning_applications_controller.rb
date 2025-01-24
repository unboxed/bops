# frozen_string_literal: true

module BopsConsultees
  class PlanningApplicationsController < ApplicationController
    before_action :authenticate_with_sgid!, only: :show
    before_action :set_planning_application, only: %i[show resend_link]
    before_action :set_consultee, only: :resend_link

    def show
      respond_to do |format|
        format.html
      end
    end

    def resend_link
      BopsCore::MagicLinkMailerJob.perform_later(
        resource: @consultee,
        subdomain: @current_local_authority.subdomain,
        planning_application: @planning_application.presented
      )

      respond_to do |format|
        format.html { redirect_to root_url, notice: "A magic link has been sent to: #{@consultee.email_address}" }
      end
    end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find_by!(reference:)
      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def set_consultee
      expired_resource = BopsCore::SgidAuthenticationService.new(sgid).expired_resource
      @consultee = @planning_application.consultation.consultees.find(expired_resource.id)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def planning_applications_scope
      @current_local_authority.planning_applications
    end

    def reference
      params[:reference]
    end

    def render_expired
      render "bops_consultees/dashboards/show"
    end
  end
end
