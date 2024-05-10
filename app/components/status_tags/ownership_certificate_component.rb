# frozen_string_literal: true

module StatusTags
  class OwnershipCertificateComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application
    delegate :ownership_certificate, to: :planning_application

    def status
      (planning_application.in_assessment? || planning_application.to_be_reviewed?) ? assessment_status : validation_status
    end

    def assessment_status
      if planning_application.validation_requests.ownership_certificates.open.any?
        :invalid
      elsif ownership_certificate.present?
        if planning_application.ownership_certificate_updated?
          :updated
        elsif ownership_certificate.current_review.complete?
          marked_as_valid?
        else
          :not_started
        end
      elsif planning_application.ownership_certificate_checked
        marked_as_valid?
      else
        :not_started
      end
    end

    def validation_status
      if planning_application.valid_ownership_certificate.nil?
        :not_started
      elsif planning_application.ownership_certificate_updated?
        :updated
      else
        marked_as_valid?
      end
    end

    def marked_as_valid?
      planning_application.valid_ownership_certificate? ? :complete : :invalid
    end
  end
end
