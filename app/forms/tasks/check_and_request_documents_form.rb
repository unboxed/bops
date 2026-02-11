# frozen_string_literal: true

module Tasks
  class CheckAndRequestDocumentsForm < Form
    include BopsCore::Tasks::CheckAndRequestDocumentsForm

    self.reference_param_name = :planning_application_reference
  end
end
