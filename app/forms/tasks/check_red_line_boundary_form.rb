# frozen_string_literal: true

module Tasks
  class CheckRedLineBoundaryForm < Form
    include BopsCore::Tasks::CheckRedLineBoundaryForm

    self.reference_param_name = :planning_application_reference
  end
end
