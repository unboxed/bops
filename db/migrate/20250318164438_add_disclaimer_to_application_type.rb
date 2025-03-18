# frozen_string_literal: true

class AddDisclaimerToApplicationType < ActiveRecord::Migration[7.2]
  def change
    add_column :application_type_configs, :disclaimer, :string
    add_column :application_types, :disclaimer, :string
  end
end
