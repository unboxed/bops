# frozen_string_literal: true

class AddServiceToApiUser < ActiveRecord::Migration[7.0]
  class ApiUser < ActiveRecord::Base; end

  def change
    add_column :api_users, :service, :string

    up_only do
      ApiUser.find_each do |api_user|
        if /swagger/i.match?(api_user.name)
          api_user.update!(service: "Swagger")
        else
          api_user.update!(service: "PlanX")
        end
      end
    end
  end
end
