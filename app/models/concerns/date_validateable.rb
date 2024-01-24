# frozen_string_literal: true

module DateValidateable
  extend ActiveSupport::Concern

  included do
    class_attribute :invalid_dates_before_type_cast, instance_writer: false
    self.invalid_dates_before_type_cast = ({})
  end

  DateBeforeTypeCast = Struct.new(:year, :month, :day) do
    def blank?
      true
    end
  end

  module ClassMethods
    def validates(*attributes, **options)
      if options.key?(:date)
        attributes.each do |attribute|
          define_method attribute do
            if attribute_date_invalid?(attribute)
              invalid_date_before_type_cast(attribute)
            else
              super()
            end
          end

          define_method :"#{attribute}=" do |value|
            reset_invalid_date_before_type_cast(attribute)
            super(value)
          rescue ArgumentError
            set_invalid_date_before_type_cast(attribute, value)
            super(nil)
          end
        end

        if !options[:date].is_a?(Hash)
          options[:date] = {}
        end

        if options.delete(:presence)
          options[:date][:presence] = true
        end
      end

      super(*attributes, **options)
    end
  end

  def attribute_date_invalid?(attribute)
    invalid_dates_before_type_cast.key?(attribute.to_s) ||
      attribute_before_type_cast(attribute.to_s).present? && self[attribute.to_s].blank?
  end

  def attribute_before_type_cast(attribute)
    invalid_date_before_type_cast(attribute) || super
  end

  def invalid_date_before_type_cast(attribute)
    invalid_dates_before_type_cast[attribute.to_s]
  end

  def reset_invalid_date_before_type_cast(attribute)
    invalid_dates_before_type_cast.delete(attribute.to_s)
  end

  def set_invalid_date_before_type_cast(attribute, value)
    if value.is_a?(Hash)
      args = value.transform_values(&:to_i).sort.map(&:last).take(3)
      invalid_dates_before_type_cast[attribute.to_s] = DateBeforeTypeCast.new(*args)
    else
      invalid_dates_before_type_cast[attribute.to_s] = value
    end
  end
end
