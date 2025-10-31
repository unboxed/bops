# frozen_string_literal: true

require "nokogiri"

class SvgValidator < ActiveModel::EachValidator
  class << self
    def schema
      @schema = Nokogiri::XML::Schema.new(schema_file)
    end

    private

    def schema_path
      Rails.root.join("xmlschema/svg.xsd")
    end

    def schema_file
      File.open(schema_path)
    end
  end

  def validate_each(record, attribute, value)
    return if value.blank?

    unless valid_svg?(value)
      record.errors.add(attribute, :invalid)
    end
  end

  private

  def valid_svg?(value)
    schema.valid?(Nokogiri::XML(value))
  rescue
    false
  end

  def schema
    self.class.schema
  end
end
