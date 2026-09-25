# frozen_string_literal: true

class MakeEnforcementReferenceNotNull < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :enforcements, "reference IS NOT NULL", name: "enforcements_reference_null", validate: false
  end
end
