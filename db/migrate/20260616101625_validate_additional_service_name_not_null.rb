# frozen_string_literal: true

class ValidateAdditionalServiceNameNotNull < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :additional_services, name: "additional_services_name_null"
    change_column_null :additional_services, :name, false
    remove_check_constraint :additional_services, name: "additional_services_name_null"
  end

  def down
    add_check_constraint :additional_services, "name IS NOT NULL", name: "additional_services_name_null", validate: false
    change_column_null :additional_services, :name, true
  end
end
