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
    ]
  end

  def audit_entry_template(audit)
    if audit.activity_type.match?("/*_validation_request_cancelled")
      "validation_request_cancelled"
    elsif audit.activity_type.include?("request") ||
          audit.activity_type.include?("document_received_at_changed") ||
          audit.activity_type.include?("submitted")
      audit.activity_type
    else
      "generic_audit_entry"
    end
  end
end
