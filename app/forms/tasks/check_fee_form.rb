# frozen_string_literal: true

module Tasks
  class CheckFeeForm < Form
    include BopsCore::Tasks::CheckFeeForm

    self.reference_param_name = :planning_application_reference
  end
end
