# frozen_string_literal: true

module BopsApi
  module PostsubmissionApplicationSchemaHelper
  
    # Formats a given date as UTC and returns it in 'YYYY-MM-DD' format.
    #
    # @param date [DateTime, Time, nil] the date to be formatted
    # @return [String, nil] the formatted date string or nil if the date is nil
    def format_postsubmission_date(date)
      date&.utc&.strftime('%Y-%m-%d')
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
