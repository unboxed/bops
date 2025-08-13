# frozen_string_literal: true

class SetDefaultStatusToEnforcements < ActiveRecord::Migration[7.2]
  def up
    validate_check_constraint :enforcements, name: "enforcements_status_null"
    change_column_null :enforcements, :status, false
    remove_check_constraint :enforcements, name: "enforcements_status_null"
    change_column_default :enforcements, :status, from: nil, to: "not_started"
  end

  def down
    add_check_constraint :enforcements, "status IS NOT NULL", name: "enforcements_status_null", validate: false
    change_column_null :enforcements, :status, true
    change_column_default :enforcements, :status, from: "not_started", to: nil
  end
end
