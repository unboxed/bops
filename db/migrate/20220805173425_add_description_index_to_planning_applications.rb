# frozen_string_literal: true

class AddDescriptionIndexToPlanningApplications < ActiveRecord::Migration[6.1]
  def up
    add_index(
      :planning_applications,
      "to_tsvector('english', description)",
      name: "index_planning_applications_on_description",
      using: :gin
    )
  end

  def down
    remove_index(
      :planning_applications,
      name: "index_planning_applications_on_description"
    )
  end
end
