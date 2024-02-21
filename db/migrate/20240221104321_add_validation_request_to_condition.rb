# frozen_string_literal: true

class AddValidationRequestToCondition < ActiveRecord::Migration[7.1]
  def change
    add_reference :conditions, :validation_request, null: true
  end
end
