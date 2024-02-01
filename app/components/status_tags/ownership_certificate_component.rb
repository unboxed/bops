# frozen_string_literal: true

module StatusTags
  class OwnershipCertificateComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def status
      if planning_application.valid_ownership_certificate.nil?
        :not_started
      elsif planning_application.valid_ownership_certificate?
        if planning_application.ownership_certificate_awaiting_validation?
          :updated
        else
          :valid
        end
      else
        :invalid
      end
    end
  end
end
