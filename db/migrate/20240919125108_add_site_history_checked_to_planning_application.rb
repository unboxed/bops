# frozen_string_literal: true

class AddSiteHistoryCheckedToPlanningApplication < ActiveRecord::Migration[7.1]
  def change
    add_column :planning_applications, :site_history_checked, :boolean, default: false, null: false
  end
end
