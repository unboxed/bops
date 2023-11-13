# frozen_string_literal: true

class AddExpiresAtToConsultees < ActiveRecord::Migration[7.0]
  def change
    add_column :consultees, :expires_at, :datetime
  end
end
