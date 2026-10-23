# frozen_string_literal: true

class AddTargetDateToEnforcement < ActiveRecord::Migration[8.1]
  def change
    add_column :enforcements, :target_date, :date
  end
end
