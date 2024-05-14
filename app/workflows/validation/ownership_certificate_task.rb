# frozen_string_literal: true

module Validation
  class OwnershipCertificateTask < WorkflowTask
    def task_list_link_text
      I18n.t("task_list_items.validating.ownership_certificate_component.link_text")
    end

    def task_list_link
      if planning_application.valid_ownership_certificate.nil?
        edit_planning_application_validation_ownership_certificate_path(planning_application)
      else
        planning_application_validation_ownership_certificate_path(planning_application)
      end
    end

    def task_list_status
      if planning_application.valid_ownership_certificate.nil?
        :not_started
      elsif planning_application.ownership_certificate_updated?
        :updated
      elsif planning_application.valid_ownership_certificate?
        :complete
      else
        :invalid
      end
    end
  end
end
