# frozen_string_literal: true

class AddToValidationRequests < ActiveRecord::Migration[7.0]
  def up
    change_column :validation_requests, :applicant_approved, :boolean, null: true, default: nil
  end

  def down
    change_column :validation_requests, :applicant_approved, :boolean, null: false, default: false
  end
end
