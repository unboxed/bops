# frozen_string_literal: true

class RenameDescriptionChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    rename_table :description_change_requests, :description_change_validation_requests
  end
end
