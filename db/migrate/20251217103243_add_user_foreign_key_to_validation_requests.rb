# frozen_string_literal: true

class AddUserForeignKeyToValidationRequests < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :validation_requests, :users, validate: false
  end
end
