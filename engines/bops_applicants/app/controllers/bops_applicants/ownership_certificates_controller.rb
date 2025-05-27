# frozen_string_literal: true

module BopsApplicants
  class OwnershipCertificatesController < ApplicationController
    before_action :set_planning_application
    before_action :require_change_access_id!
    before_action :set_validation_request
    before_action :redirect_to_validation_requests_page, if: :certificate_submitted?
    before_action :set_ownership_certificate_form

    def new
      respond_to do |format|
        format.html
      end
    end

    def create
      respond_to do |format|
        if @ownership_certificate.save
          format.html { redirect_to validation_requests_url(access_control_params), notice: t(".success") }
        elsif @ownership_certificate.failed?
          format.html { render :new, alert: t(".failure_html", feedback_email: current_local_authority.feedback_email) }
        else
          format.html { render :new }
        end
      end
    end

    private

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def planning_application_param
      params.fetch(:planning_application_reference)
    end

    def validation_request_id
      Integer(params.fetch(:validation_request_id))
    end

    def certificate_submitted?
      @validation_request.ownership_certificate_submitted?
    end

    def redirect_to_validation_requests_page
      redirect_to validation_requests_url(access_control)
    end

    def set_ownership_certificate_form
      @ownership_certificate = BopsApplicants::OwnershipCertificateForm.new(@planning_application, @validation_request, params)
    end
  end
end
