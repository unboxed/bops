# frozen_string_literal: true

module AuditableModel
  extend ActiveSupport::Concern

  included do
    private

    def audit(activity_type, audit_comment = nil, activity_information = nil)
      Audit.create!(
        planning_application_id: planning_application_id,
        user: Current.user,
        audit_comment: audit_comment,
        activity_information: activity_information,
        activity_type: activity_type,
        api_user: Current.api_user
      )
    end

    def planning_application_id
      if is_a?(PlanningApplication)
        id
      elsif planning_application.present?
        planning_application.id
      else
        raise ArgumentError, "Planning application is missing"
      end
    end
  end
end
