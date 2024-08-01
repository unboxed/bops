# frozen_string_literal: true

module Bops
  module Holidays
    def self.holidays(from: Time.zone.today, to: 1.year.after(from))
      # nb. if we ever need to support councils outside england this third
      # parameter may need to change since scotland and the north of ireland
      # have different bank holidays (welsh bank holidays are the same as in
      # england but could also potentially differ in future)
      ::Holidays.between(from, to, :gb_eng, :observed).pluck(:date)
    end

    def self.days_after_plus_holidays(from_date:, count:)
      count = count.days unless count.is_a? ActiveSupport::Duration
      holidays_in_range = holidays(from: from_date, to: from_date + count)
      from_date + count + holidays_in_range.count.days
    end
  end
end
