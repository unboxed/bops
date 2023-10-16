# frozen_string_literal: true

Given("the date is {int}-{int}-{int}") do |day, month, year|
  travel_to Time.zone.local(year, month, day)
end

Given("the date is {int}-{int}-{int} and the planning application is validated") do |day, month, year|
  travel_to Time.zone.local(year, month, day)

  steps("Given the planning application is validated")

  visit root_path
end

Given("the time is {int}:{int} on the {int}-{int}-{int}") do |hour, minutes, day, month, year|
  travel_to Time.zone.local(year, month, day, hour, minutes)
end

Given("the time is {int}:{int}") do |hour, minutes|
  now = Time.zone.now
  destination = Time.zone.local(now.year, now.month, now.day, hour, minutes)

  # Travelling forward in time will force the Devise session to expire
  destination = destination.advance(days: -1) if destination.after?(now)

  travel_to destination
end

Given("the time is {int}:{int} and the planning application is validated") do |hour, minutes|
  steps("Given the time is #{hour}:#{minutes}")
  steps("Given the planning application is validated")

  visit root_path
end
