# frozen_string_literal: true

class AddLonlatToNeighbour < ActiveRecord::Migration[7.1]
  def change
    add_column :neighbours, :lonlat, :st_point, geographic: true
  end
end
