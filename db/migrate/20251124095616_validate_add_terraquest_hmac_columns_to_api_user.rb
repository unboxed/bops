# frozen_string_literal: true

class ValidateAddTerraquestHmacColumnsToApiUser < ActiveRecord::Migration[8.0]
  def up
    validate_check_constraint :api_users, name: "api_users_authentication_type_null"
    change_column_null :api_users, :authentication_type, false
    remove_check_constraint :api_users, name: "api_users_authentication_type_null"
  end

  def down
    add_check_constraint :api_users, "authentication_type IS NOT NULL", name: "api_users_authentication_type_null", validate: false
    change_column_null :api_users, :authentication_type, true
  end
end
