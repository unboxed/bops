# frozen_string_literal: true

class AddColumnToDescriptionChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :description_change_validation_requests, :notified_at, :date
  end
end
