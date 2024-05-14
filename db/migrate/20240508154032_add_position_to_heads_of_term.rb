# frozen_string_literal: true

class AddPositionToHeadsOfTerm < ActiveRecord::Migration[7.1]
  def change
    add_column :terms, :position, :integer
  end
end
