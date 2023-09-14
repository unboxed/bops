# frozen_string_literal: true

day_month_only = "%-d %B"
day_month_year = "#{day_month_only} %Y"

Date::DATE_FORMATS[:day_month_year] = day_month_year
Time::DATE_FORMATS[:day_month_year] = "#{day_month_year} %H:%M"

Date::DATE_FORMATS[:default] = Date::DATE_FORMATS[:day_month_year]
Time::DATE_FORMATS[:default] = Time::DATE_FORMATS[:day_month_year]

day_month_year_slashes = "%d/%m/%Y"

Date::DATE_FORMATS[:day_month_year_slashes] = day_month_year_slashes
Time::DATE_FORMATS[:day_month_year_slashes] = day_month_year_slashes

Date::DATE_FORMATS[:day_month_only] = day_month_only
Time::DATE_FORMATS[:time_only] = "%H:%M"
