# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    private

    def audit(activity_type, audit_comment = nil, activity_information = nil, api_user = nil)
      Audit.create!(
        planning_application_id: @planning_application.id,
        user: current_user,
        audit_comment: audit_comment,
        activity_information: activity_information,
        activity_type: activity_type,
        api_user: api_user
      )
    end
  end
end
