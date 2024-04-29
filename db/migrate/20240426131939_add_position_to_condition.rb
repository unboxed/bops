# frozen_string_literal: true

class AddPositionToCondition < ActiveRecord::Migration[7.1]
  def change
    add_column :conditions, :position, :integer
  end
end
