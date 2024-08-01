# frozen_string_literal: true

require "bops/holidays"

BusinessTime::Config.load(Rails.root.join("config/business_time.yml").to_s)

# or you can configure it manually:  look at me!  I'm Tim Ferriss!
#  BusinessTime::Config.beginning_of_workday = "10:00 am"
#  BusinessTime::Config.end_of_workday = "11:30 am"
#  BusinessTime::Config.holidays << Date.parse("August 4th, 2010")

module Bops
  module TimeExtensions
    module ClassMethods
      def next_immediate_business_day(time)
        ::Time.roll_forward(time).to_datetime
      end
    end
  end
end

class Time
  extend Bops::TimeExtensions::ClassMethods
end

Bops::Holidays.holidays(from: Time.zone.local(2020, 1, 1), to: 1.year.from_now).map do |holiday|
  BusinessTime::Config.holidays << holiday
end
