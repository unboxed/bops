# frozen_string_literal: true

Time::DATE_FORMATS[:day_month_year] = Date::DATE_FORMATS[:day_month_year] = "%-d %B %Y"
Time::DATE_FORMATS[:day_month_year_time] = "%-d %B %Y %H:%M"
