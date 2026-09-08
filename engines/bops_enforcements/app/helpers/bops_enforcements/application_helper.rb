# frozen_string_literal: true

module BopsEnforcements
  module ApplicationHelper
    include BopsCore::ApplicationHelper
    include BreadcrumbNavigationHelper

    def activity(type_of_activity, args = nil)
      scope = %i[audits types]

      scope << :no_user if type_of_activity == "assigned" && args.blank?

      t(type_of_activity, raise: true, scope:, args:)
    rescue I18n::MissingTranslationData
      raise ArgumentError, "Activity type: #{type_of_activity} is not valid"
    end

    def get_relevant_audit_information(audit)
      audit.audit_comment.nil? ? audit.activity_information : audit.audit_comment
    end

    def valid_json?(comment)
      JSON.parse(comment)
      true
    rescue JSON::ParserError, TypeError
      false
    end
  end
end
