# frozen_string_literal: true

class AddMissingPlanningApplicationForeignKeyToSiteNotices < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :site_notices, :planning_applications
  end
end
