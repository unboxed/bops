# frozen_string_literal: true

class CreateApplicants < ActiveRecord::Migration[6.0]
  def change
    create_table :applicants do |t|
      t.string :name
      t.string :phone
      t.string :email

      t.timestamps
    end
  end
end
