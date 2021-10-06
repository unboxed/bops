# frozen_string_literal: true

class CreateApiUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :api_users do |t|
      t.string :name, null: false, default: ""
      t.string :token, null: false, default: ""

      t.timestamps
    end
  end
end
