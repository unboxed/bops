# frozen_string_literal: true

class AddProposedExpiryDateToValidationRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :validation_requests, :proposed_expiry_date, :datetime
  end
end
