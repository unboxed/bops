# frozen_string_literal: true

class AddReferenceToEnforcement < ActiveRecord::Migration[8.1]
  def change
    add_column :enforcements, :reference, :string
  end
end
