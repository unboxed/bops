# frozen_string_literal: true

module AuditableModel
  extend ActiveSupport::Concern

  included do
    private

    def audit_created!(activity_type:, activity_information: nil, audit_comment: nil)
      audits.create!(
        user: user || nil,
        activity_type: activity_type,
        activity_information: activity_information,
        audit_comment: audit_comment,
        api_user: api_user || nil
      )
    end
  end
end
