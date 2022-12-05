# frozen_string_literal: true

class AddSiteMapCorrectToConsistencyChecklists < ActiveRecord::Migration[6.1]
  def change
    add_column(
      :consistency_checklists,
      :site_map_correct,
      :integer,
      default: 0,
      null: false
    )
  end
end
