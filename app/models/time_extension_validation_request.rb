# frozen_string_literal: true

class TimeExtensionValidationRequest < ValidationRequest

  def audit_comment
    {
      previous: planning_application.expiry_date,
      proposed: proposed_expiry_date
    }.to_json
  end
end
