# frozen_string_literal: true

class AddStatusToApplicationTypes < ActiveRecord::Migration[7.1]
  class ApplicationType < ActiveRecord::Base; end

  def change
    add_column :application_types, :status, :string

    up_only do
      ApplicationType.find_each do |type|
        type.update!(status: "active")
      end

      change_column_default :application_types, :status, "inactive"
      change_column_null :application_types, :status, false
    end
  end
end
