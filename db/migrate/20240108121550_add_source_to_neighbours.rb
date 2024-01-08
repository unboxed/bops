# frozen_string_literal: true

class AddSourceToNeighbours < ActiveRecord::Migration[7.0]
  def change
    add_column :neighbours, :source, :string
  end
end
