# frozen_string_literal: true

day_month_year = "%-d %B %Y"

Date::DATE_FORMATS[:day_month_year] = day_month_year
Time::DATE_FORMATS[:day_month_year] = "#{day_month_year} %H:%M"

Date::DATE_FORMATS[:default] = Date::DATE_FORMATS[:day_month_year]
Time::DATE_FORMATS[:default] = Time::DATE_FORMATS[:day_month_year]
