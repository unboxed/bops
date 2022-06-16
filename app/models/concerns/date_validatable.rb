# frozen_string_literal: true

module DateValidatable
  extend ActiveSupport::Concern

  included do
    validate :all_dates_are_valid
  end

  class_methods do
    def handle_invalid_dates(*attributes)
      attributes.each do |attribute|
        attr_accessor "#{attribute}_day"
        attr_accessor "#{attribute}_month"
        attr_accessor "#{attribute}_year"

        define_method("#{attribute}_is_valid") do
          values = [
            send("#{attribute}_year"),
            send("#{attribute}_month"),
            send("#{attribute}_day")
          ]

          return if values.all?(&:blank?)

          integers = values.map(&:to_i)

          unless values.all?(&:present?) && integers.all?(&:positive?) && Date.valid_date?(*integers)
            errors.add(attribute, "is invalid") and return
          end

          send("#{attribute}=", Date.new(*integers))
        end
      end

      define_method(:all_dates_are_valid) do
        attributes.each do |attribute|
          send("#{attribute}_is_valid")
        end
      end
    end
  end
end

# to do:
# split #handle_invalid_dates into smaller methods
