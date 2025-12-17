# frozen_string_literal: true

class ValidateAddUserForeignKeyToValidationRequests < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :validation_requests, :users
  end
end
