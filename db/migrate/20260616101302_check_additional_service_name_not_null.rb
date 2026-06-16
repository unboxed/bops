# frozen_string_literal: true

class CheckAdditionalServiceNameNotNull < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :additional_services, "name IS NOT NULL", name: "additional_services_name_null", validate: false
  end
end
