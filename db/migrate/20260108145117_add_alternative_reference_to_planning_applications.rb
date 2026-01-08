# frozen_string_literal: true

class AddAlternativeReferenceToPlanningApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :planning_applications, :alternative_reference, :string
  end
end
