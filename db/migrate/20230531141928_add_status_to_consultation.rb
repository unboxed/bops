# frozen_string_literal: true

class AddStatusToConsultation < ActiveRecord::Migration[7.0]
  def change
    add_column :consultations, :status, :string, default: "not_started", null: false
  end
end
