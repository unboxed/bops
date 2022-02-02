# frozen_string_literal: true

module AuditableModel
  extend ActiveSupport::Concern

  included do
    private

    def audit_created!(activity_type:)
      audits.create!(
        user: user || nil,
        activity_type: activity_type,
        activity_information: api_user&.name || user&.name,
        api_user: api_user || nil
      )
    end
  end
end
