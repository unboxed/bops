# frozen_string_literal: true

class ValidateAddEnableNotifyToLocalAuthorities < ActiveRecord::Migration[8.0]
  def up
    validate_check_constraint :local_authorities, name: "local_authorities_enable_notify_null"
    change_column_null :local_authorities, :enable_notify, false
    remove_check_constraint :local_authorities, name: "local_authorities_enable_notify_null"
  end

  def down
    add_check_constraint :local_authorities, "enable_notify IS NOT NULL", name: "local_authorities_enable_notify_null", validate: false
    change_column_null :local_authorities, :enable_notify, true
  end
end
