# frozen_string_literal: true

module Consultable
  extend ActiveSupport::Concern

  included do
    before_validation :start_deadline, unless: :consultation_started?

    with_options allow_nil: true do
      delegate :consultation, to: :planning_application
      delegate :start_date, to: :consultation, prefix: true
      delegate :end_date, to: :consultation, prefix: true
      delegate :started?, to: :consultation, prefix: true
      delegate :start_deadline, to: :consultation
    end

    private

    def new_consultation_end_date
      [event_at && (event_at + consultation.period_days).end_of_day, consultation_end_date].compact.max
    end

    def extend_consultation!
      consultation.update!(end_date: new_consultation_end_date)
    end

    def event_at
      case self.class.name
      when "PressNotice"
        published_at
      when "SiteNotice"
        displayed_at
      else
        raise ArgumentError "Method not supported for class: #{self.class.name}"
      end
    end
  end
end
