# frozen_string_literal: true

class AddQuantityAndLocationInstructionsToSiteNotices < ActiveRecord::Migration[8.0]
  def up
    add_column :site_notices, :quantity, :integer, default: 1, null: false
    add_column :site_notices, :location_instructions, :text

    safety_assured { execute("UPDATE site_notices SET quantity = 1 WHERE quantity IS NULL") }
  end

  def down
    remove_column :site_notices, :location_instructions
    remove_column :site_notices, :quantity
  end
end
