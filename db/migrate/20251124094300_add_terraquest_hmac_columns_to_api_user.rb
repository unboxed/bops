# frozen_string_literal: true

class AddTerraquestHmacColumnsToApiUser < ActiveRecord::Migration[8.0]
  class ApiUser < ActiveRecord::Base; end

  def change
    add_column :api_users, :authentication_type, :string
    add_column :api_users, :product_id, :string
    add_column :api_users, :client_id, :string
    add_column :api_users, :client_secret, :string

    up_only do
      ApiUser.update_all(authentication_type: "bearer")

      change_column_default :api_users, :authentication_type, "bearer"
      add_check_constraint :api_users, "authentication_type IS NOT NULL", name: "api_users_authentication_type_null", validate: false
    end
  end
end
