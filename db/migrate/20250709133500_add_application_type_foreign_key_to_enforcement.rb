# frozen_string_literal: true

class AddApplicationTypeForeignKeyToEnforcement < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :enforcements, :application_types, validate: false
  end
end
