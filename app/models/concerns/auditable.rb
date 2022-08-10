# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    private

    def audit!(activity_type:, activity_information: nil, audit_comment: nil)
      audits.create!(
        user: current_user,
        activity_type: activity_type,
        activity_information: activity_information,
        audit_comment: audit_comment,
        api_user: current_api_user,
        automated_activity: no_current_user?
      )
    end

    def no_current_user?
      current_user.blank? && current_api_user.blank?
    end

    def current_user
      @current_user ||= Current.user
    end

    def current_api_user
      @current_api_user ||= Current.api_user
    end
  end
end
