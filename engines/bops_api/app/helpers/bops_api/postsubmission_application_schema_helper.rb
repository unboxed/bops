# frozen_string_literal: true

module BopsApi
  module PostsubmissionApplicationSchemaHelper
    # Formats a given date in 'YYYY-MM-DD' format.
    # Use this when formatting dates stored as datetimes in the database to date strings until they can be converted
    #
    # @param date [DateTime, Time, nil] the date to be formatted
    # @return [String, nil] the formatted date string or nil if the date is nil
    #
    # Note: This method converts the given date to a Date object, which removes the time component,
    # and then converts it to a string in 'YYYY-MM-DD' format. This method does not account for time zones
    # as it only deals with the date part so data could be lost if the time zone is important.
    def format_postsubmission_date(date)
      date&.to_date&.to_s
    end

    # Formats a given date as UTC and returns it in ISO 8601 format.
    #
    # @param date [DateTime, Time, nil] the date to be formatted
    # @return [String, nil] the formatted date string or nil if the date is nil
    def format_postsubmission_datetime(date)
      date&.utc&.iso8601
    end
  end
end
