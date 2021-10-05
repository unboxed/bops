# frozen_string_literal: true

class DropApplicantsTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :applicants
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
