# frozen_string_literal: true

class AddOtherReasonToPressNotices < ActiveRecord::Migration[7.0]
  class PressNotice < ActiveRecord::Base; end

  def change
    add_column :press_notices, :other_reason, :text

    up_only do
      PressNotice.find_each do |press_notice|
        next unless Hash === press_notice.reasons

        press_notice.other_reason = press_notice.reasons["other"].presence
        press_notice.reasons = press_notice.reasons.keys
        press_notice.save!
      end
    end
  end
end
