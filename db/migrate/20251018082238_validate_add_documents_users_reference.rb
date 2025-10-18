# frozen_string_literal: true

class ValidateAddDocumentsUsersReference < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :documents, :users
  end
end
