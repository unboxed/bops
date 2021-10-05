# frozen_string_literal: true

class DropSites < ActiveRecord::Migration[6.0]
  def up
    drop_table "sites"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
