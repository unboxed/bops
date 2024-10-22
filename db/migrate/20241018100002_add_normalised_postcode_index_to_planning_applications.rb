# frozen_string_literal: true

class AddNormalisedPostcodeIndexToPlanningApplications < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :planning_applications, "LOWER(replace(postcode, ' ', ''))", algorithm: :concurrently
  end
end
