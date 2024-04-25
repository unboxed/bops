# frozen_string_literal: true

class AddPositionToInformative < ActiveRecord::Migration[7.1]
  def change
    add_column :informatives, :position, :integer
  end
end
