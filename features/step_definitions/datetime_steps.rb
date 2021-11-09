# frozen_string_literal: true

Given("the date is year: {int}, month: {int}, day: {int}") do |year, month, day|
  travel_to Time.zone.local(year, month, day)
end
