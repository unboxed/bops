# frozen_string_literal: true

module AccordionSections
  class AuditLogComponent < AccordionSections::BaseComponent
    include AuditHelper

    private

    def last_audit
      @last_audit ||= planning_application.audits.last
    end
  end
end
