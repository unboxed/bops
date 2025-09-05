# frozen_string_literal: true

# rubocop:disable Rails/ThreeStateBooleanColumn
class AddSection55DevelopmentToPlanningApplications < ActiveRecord::Migration[7.2]
  def change
    add_column :planning_applications, :section_55_development, :boolean, default: nil, null: true
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
