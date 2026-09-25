# frozen_string_literal: true

class LocalAuthority::ApplicationNumber < ApplicationRecord
  belongs_to :local_authority

  class << self
    def current_year(year = Time.zone.today.year)
      find_or_create_by!(year:) do |counter|
        counter.application_number = 99
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    delegate :next_application_number, to: :current_year
  end

  def next_application_number
    with_lock do
      increment!(:application_number)
    end

    application_number
  end

  private

  def year
    @year ||= Time.zone.today.year
  end
end
