# frozen_string_literal: true

class AddCancelledAtToConditions < ActiveRecord::Migration[7.1]
  def change
    add_column :conditions, :cancelled_at, :datetime
  end
end
