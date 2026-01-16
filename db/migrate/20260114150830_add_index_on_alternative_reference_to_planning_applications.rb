# frozen_string_literal: true

class AddIndexOnAlternativeReferenceToPlanningApplications < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :planning_applications, :alternative_reference, using: :gin, algorithm: :concurrently
  end
end
