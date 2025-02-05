# frozen_string_literal: true

module BopsConsultees
  class PlanningApplicationsController < ApplicationController
    before_action :authenticate_with_sgid!, only: :show
    before_action :set_planning_application, only: %i[show resend_link]
    before_action :set_consultee, only: %i[show resend_link]
    before_action :set_consultee_response, only: :show
    before_action :ensure_magic_link_resend_allowed, only: :resend_link

    def show
      respond_to do |format|
        format.html
      end
    end

    def resend_link
      BopsCore::MagicLinkMailerJob.perform_later(
        resource: @consultee,
        planning_application: @planning_application.presented
      )

      respond_to do |format|
        format.html { redirect_to root_url, notice: t(".success", email: @consultee.email_address) }
      end
    end

    private

    def set_consultee
      expired_resource = BopsCore::SgidAuthenticationService.new(sgid).expired_resource
      @consultee = @planning_application.consultation.consultees.find(expired_resource.id)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def set_consultee_response
      @consultee_response = @consultee.responses.first_or_initialize
    end

    def render_expired
      render "bops_consultees/dashboards/show"
    end

    def ensure_magic_link_resend_allowed
      return if @consultee.can_resend_magic_link?

      flash.now[:alert] = t(".failure")
      @expired_resource = @consultee
      render_expired
    end
  end
end
