# frozen_string_literal: true

class DropNotNullConstraintsOnConsideration < ActiveRecord::Migration[7.2]
  def change
    up_only do
      change_column_null :considerations, :assessment, true
      change_column_null :considerations, :conclusion, true
    end
  end
end
