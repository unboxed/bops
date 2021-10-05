# frozen_string_literal: true

class AddArchiveReasonToDrawings < ActiveRecord::Migration[6.0]
  def change
    add_column :drawings, :archive_reason, :integer
  end
end
