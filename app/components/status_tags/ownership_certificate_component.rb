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
      elsif planning_application.valid_ownership_certificate
        :complete
      elsif ownership_certificate.present?
        if ownership_certificate.current_review.complete?
          planning_application.valid_ownership_certificate? ? :complete : :invalid
        else
          :not_started
        end
      else
        :not_started
      end
    end

    def validation_status
      if planning_application.valid_ownership_certificate.nil?
        :not_started
      elsif ownership_certificate.present?
        if planning_application.ownership_certificate_awaiting_validation?
          :updated
        else
          planning_application.valid_ownership_certificate? ? :valid : :invalid
        end
      else
        :invalid
      end
    end
  end
end
