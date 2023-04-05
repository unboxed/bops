# frozen_string_literal: true

class ChangeAwaitingCorrectionAtColumnName < ActiveRecord::Migration[7.0]
  def change
    rename_column :planning_applications, :awaiting_correction_at, :to_be_reviewed_at
  end
end
