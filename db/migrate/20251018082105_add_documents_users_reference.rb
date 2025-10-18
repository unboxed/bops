# frozen_string_literal: true

class AddDocumentsUsersReference < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :documents, :users, if_not_exists: true, validate: false
  end
end
