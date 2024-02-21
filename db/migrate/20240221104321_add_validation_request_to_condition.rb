# frozen_string_literal: true

class AddValidationRequestToCondition < ActiveRecord::Migration[7.1]
  def change
    add_reference :validation_requests, :condition, null: true
  end
end
