# frozen_string_literal: true

module DateValidatable
  extend ActiveSupport::Concern

  included do
    validate :all_dates_are_valid
  end

  class_methods do
    def handle_invalid_dates(*attributes)
      attributes.each do |attribute|
        define_attr_accessors(attribute)
        define_attribute_is_valid(attribute)
      end

      define_all_dates_are_valid(attributes)
    end

    def define_attr_accessors(attribute)
      attr_accessor "#{attribute}_day"
      attr_accessor "#{attribute}_month"
      attr_accessor "#{attribute}_year"
    end

    def define_attribute_is_valid(attribute)
      define_method("#{attribute}_is_valid") do
        values = [
          send("#{attribute}_year"),
          send("#{attribute}_month"),
          send("#{attribute}_day")
        ]

        return if values.all?(&:blank?)

        integers = values.map(&:to_i)

        if are_valid_values?(values, integers)
          send("#{attribute}=", Date.new(*integers))
        else
          errors.add(attribute, I18n.t("errors.messages.invalid"))
        end
      end
    end

    def define_all_dates_are_valid(attributes)
      define_method(:all_dates_are_valid) do
        attributes.each do |attribute|
          send("#{attribute}_is_valid")
        end
      end
    end
  end

  def are_valid_values?(values, integers)
    values.all?(&:present?) &&
      integers.all?(&:positive?) &&
      Date.valid_date?(*integers)
  end
end
