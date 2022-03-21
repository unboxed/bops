# frozen_string_literal: true

class AddValidFeeToPlanningApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :planning_applications, :valid_fee, :boolean
  end
end
