# frozen_string_literal: true

class ValidateApplicationTypeForeignKeyOnEnforcement < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :enforcements, :application_types
  end
end
