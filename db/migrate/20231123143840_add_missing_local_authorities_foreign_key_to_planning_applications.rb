# frozen_string_literal: true

class AddMissingLocalAuthoritiesForeignKeyToPlanningApplications < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :planning_applications, :local_authorities
  end
end
