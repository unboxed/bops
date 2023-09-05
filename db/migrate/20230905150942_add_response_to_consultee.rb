# frozen_string_literal: true

class AddResponseToConsultee < ActiveRecord::Migration[7.0]
  def change
    add_column :consultees, :response, :text
  end
end
