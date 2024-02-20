# frozen_string_literal: true

module LocalPolicyAreaHelper
  def enabled_status(local_policy_area)
    local_policy_area.enabled? ? "Yes" : "No"
  end
end
