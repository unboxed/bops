# frozen_string_literal: true

module Audits
  class ActivityComponent < ViewComponent::Base
    def initialize(audit:)
      @audit = audit
      @activity_type = audit.activity_type
    end

    attr_reader :audit, :activity_type

    def audit_template
      if activity_type.match?("/*_validation_request_cancelled")
        "validation_request_cancelled"
      elsif activity_type.include?("request") ||
          activity_type.include?("document_received_at_changed") ||
          activity_type.include?("submitted")
        activity_type
      else
        "generic_audit_entry"
      end
    end
  end
end
