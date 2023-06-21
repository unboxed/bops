# frozen_string_literal: true

class AddSelectedToNeighbour < ActiveRecord::Migration[7.0]
  def change
    add_column :neighbours, :selected, :boolean, default: true
  end
end
