# frozen_string_literal: true

module BopsConsultees
  class PlanningApplicationsController < ApplicationController
    before_action :set_planning_application, only: %i[show resend_link]
    before_action :set_consultee, only: %i[show resend_link]
    before_action :authenticate_with_sgid!, only: :show
    before_action :ensure_consultee_responses_allowed, only: :show
    before_action :set_consultee_response, only: :show
    before_action :set_consultee_response_form_email, only: :show
    before_action :ensure_magic_link_resend_allowed, only: :resend_link

    def index
      respond_to do |format|
        format.html
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def resend_link
      @form = BopsCore::MagicLink::ExpiredMagicLinkForm.new(
        email: params.dig(:magic_link_expired_magic_link_form, :email),
        consultee: @consultee
      )

      if @form.valid?
        BopsCore::MagicLinkMailerJob.perform_later(
          resource: @consultee,
          planning_application: @planning_application.presented,
          email: params.dig(:magic_link_expired_magic_link_form, :email)
        )
        respond_to do |format|
          format.html { redirect_to root_url, notice: t(".success", email: params.dig(:magic_link_expired_magic_link_form, :email)) }
        end
      else
        @expired_resource = @consultee
        render_expired
      end
    end

    private

    def set_consultee
      expired_resource = BopsCore::SgidAuthenticationService.new(sgid).expired_resource
      if expired_resource.nil?
        render_not_found and return
      end

      @consultee = @planning_application.consultation.consultees.find(expired_resource.id)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def set_consultee_response
      @consultee_response = @consultee.responses.new
    end

    def set_consultee_response_form_email
      last_consultee_response = @consultee.responses.where.not(received_at: nil).order(received_at: :desc).last
      @response_form_email = last_consultee_response&.email.presence || @consultee.email_address
    end

    def render_consultee_responses_closed
      @not_required = true
      render "bops_consultees/planning_applications/index"
    end

    def render_expired
      @form ||= BopsCore::MagicLink::ExpiredMagicLinkForm.new(
        email: @consultee.email_address,
        consultee: @consultee
      )
      render "bops_consultees/planning_applications/index"
    end

    def ensure_magic_link_resend_allowed
      return if @consultee.can_resend_magic_link?

      flash.now[:alert] = t(".failure")
      @expired_resource = @consultee
      render_expired
    end

    def ensure_consultee_responses_allowed
      if @planning_application.consultee_responses_closed?
        render_consultee_responses_closed
      elsif @expired_resource.present?
        render_expired
      end
    end
  end
end
