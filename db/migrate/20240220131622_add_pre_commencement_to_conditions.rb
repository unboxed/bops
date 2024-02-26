# frozen_string_literal: true

class AddPreCommencementToConditions < ActiveRecord::Migration[7.1]
  def change
    add_column :condition_sets, :pre_commencement, :boolean, null: false, default: false
  end
end
