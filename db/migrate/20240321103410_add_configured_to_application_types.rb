# frozen_string_literal: true

class AddConfiguredToApplicationTypes < ActiveRecord::Migration[7.1]
  def change
    add_column :application_types, :configured, :boolean

    up_only do
      ApplicationType.find_each do |type|
        type.update!(configured: true)
      end

      change_column_default :application_types, :configured, false
      change_column_null :application_types, :configured, false
    end
  end
end
