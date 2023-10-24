# frozen_string_literal: true

class AddUniqueIndexOnAddressAndConsultationForNeighbours < ActiveRecord::Migration[7.0]
  def change
    add_index :neighbours, "LOWER(address), consultation_id",
      unique: true,
      name: "index_neighbours_on_lower_address_and_consultation_id"
  end
end
