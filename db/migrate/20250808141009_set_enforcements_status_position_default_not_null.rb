# frozen_string_literal: true

class SetEnforcementsStatusPositionDefaultNotNull < ActiveRecord::Migration[7.2]
  def change
    add_check_constraint :enforcements, "status IS NOT NULL", name: "enforcements_status_null", validate: false
  end
end
