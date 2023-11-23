# frozen_string_literal: true

class AddMissingConsultationForeignKeyToNeighbours < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :neighbours, :consultations
  end
end
