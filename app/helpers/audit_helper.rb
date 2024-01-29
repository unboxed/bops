# frozen_string_literal: true

module AuditHelper
  def activity(type_of_activity, args = nil)
    scope = %i[audits types]

    scope << :no_user if type_of_activity == "assigned" && args.blank?

    t(type_of_activity, raise: true, scope:, args:)
  rescue I18n::MissingTranslationData
    raise ArgumentError, "Activity type: #{type_of_activity} is not valid"
  end

  def audit_user_name(audit)
    if applicant_activity_types.include?(audit.activity_type)
      t("audit_user_name.bops_applicants")
    elsif audit.api_user.present?
      audit_api_user_name(audit)
    elsif audit.user.present?
      audit.user.name
    elsif audit.automated_activity?
      t("audit_user_name.system")
    else
      t("audit_user_name.deleted")
    end
  end

  def audit_api_user_name(audit)
    if applicant_activity_types.include?(audit.activity_type)
      t("audit_user_name.applicant", api_user_name: audit.api_user.name)
    else
      audit.api_user.name
    end
  end

  def applicant_activity_types
    %w[
      description_change_validation_request_received
      replacement_document_validation_request_received
      additional_document_validation_request_received
      red_line_boundary_change_validation_request_received
      other_change_validation_request_received
      fee_change_validation_request_received
    ]
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
