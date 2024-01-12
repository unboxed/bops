# frozen_string_literal: true

class AddValidDescriptionToPlanningApplication < ActiveRecord::Migration[7.0]
  def change
    add_column :planning_applications, :valid_description, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
