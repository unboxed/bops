# frozen_string_literal: true

class RemovePressSentAtFromPressNotices < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :press_notices, :press_sent_at, :datetime }
  end
end
