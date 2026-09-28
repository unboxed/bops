# frozen_string_literal: true

class RemovePlanningApplicationNumberUniqueIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :planning_applications, %i[application_number local_authority_id], unique: true
  end
end
