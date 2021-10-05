# frozen_string_literal: true

class ChangeColumnNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null(:applicants, :agent_id, true)
  end
end
