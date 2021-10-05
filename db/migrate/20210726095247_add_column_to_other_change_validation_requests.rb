# frozen_string_literal: true

class AddColumnToOtherChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :other_change_validation_requests, :notified_at, :date
  end
end
