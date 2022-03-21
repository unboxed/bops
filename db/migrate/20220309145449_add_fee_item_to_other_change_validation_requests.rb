# frozen_string_literal: true

class AddFeeItemToOtherChangeValidationRequests < ActiveRecord::Migration[6.1]
  def change
    add_column :other_change_validation_requests, :fee_item, :boolean, default: false
  end
end
