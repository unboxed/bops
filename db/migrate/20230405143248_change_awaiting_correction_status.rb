# frozen_string_literal: true

class ChangeAwaitingCorrectionStatus < ActiveRecord::Migration[7.0]
  def change
    up_only do
      execute <<~SQL.squish
        UPDATE planning_applications
        SET "status" = 'to_be_reviewed'
        WHERE "status" = 'awaiting_correction';
      SQL
    end
  end
end
