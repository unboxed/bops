# frozen_string_literal: true

class RemoveResponseFromConsultee < ActiveRecord::Migration[7.0]
  def change
    remove_column :consultees, :response, :text
  end
end
