# frozen_string_literal: true

class DateValidator < ActiveModel::EachValidator
  VALIDATIONS = {
    is: :==,
    before: :>,
    after: :<,
    on_or_before: :>=,
    on_or_after: :<=,
    between: :cover?
  }.freeze

  ERROR_TYPES = {
    is: :date_is_not,
    before: :date_not_before,
    after: :date_not_after,
    on_or_before: :date_not_on_or_before,
    on_or_after: :date_not_on_or_after,
    between: :date_not_between
  }.freeze

  DATE_FORMAT = "%d/%m/%Y"

  def validate_each(record, attribute, value)
    if record.attribute_date_invalid?(attribute)
      record.errors.add(attribute, :date_invalid)
    elsif options[:presence] && value.blank?
      record.errors.add(attribute, :date_blank)
    end

    VALIDATIONS.each do |validation, comparator|
      next if value.blank?
      next unless options.key?(validation)

      restriction = resolve(record, options.fetch(validation))

      unless restriction.respond_to?(comparator)
        raise ArgumentError, <<~MESSAGE
          The value of restriction ':#{validation}' for ':#{attribute}' does not respond to the method ':#{comparator}'
        MESSAGE
      end

      unless restriction.public_send(comparator, value)
        add_error(record, attribute, validation, restriction)
      end
    end
  end

  private

  def resolve(record, restriction)
    if restriction.respond_to?(:call)
      restriction.call(record)
    elsif restriction.respond_to?(:to_date)
      restriction.to_date
    elsif restriction.respond_to?(:to_sym)
      if Date.respond_to?(restriction)
        Date.public_send(restriction)
      else
        record.send(restriction)
      end
    else
      restriction
    end
  end

  def format_date(date)
    date.strftime(options.fetch(:format, DATE_FORMAT))
  end

  def add_error(record, attribute, validation, restriction)
    type = ERROR_TYPES.fetch(validation)
    message = {}

    if options.key?(:message)
      message[:message] = options.fetch(:message)
    end

    if validation == :between
      message[:start_date] = format_date(restriction.first)
      message[:end_date] = format_date(restriction.last)
    else
      message[:date] = format_date(restriction)
    end

    record.errors.add(attribute, type, **message)
  end
end
