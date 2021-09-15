# frozen_string_literal: true

class PolicyClass
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id
  attribute :name
  attribute :part
  attribute :policies

  class << self
    def all_parts
      # NOTE: we might do multiple schedules at some point in the
      # future but no need to worry about it now
      I18n.t("schedules").first[:parts]
    end

    def classes_for_part(number)
      all_parts[number.to_i][:classes]
        .map { |h| h[:part] = number; h }
        .map { |h| PolicyClass.new(h) }
    end
  end

  def stamp_part!(number)
    part = number
  end

  def stamp_status!
    policies.each do |policy|
      policy["status"] = "undetermined"
    end
  end

  def status
    return "undetermined" if policies.any? { |p| p["status"] == "undetermined" }
    return "does not comply" if policies.any? { |p| p["status"] == "does_not_comply" }

    "complies"
  end

  def as_json(options = nil)
    attributes.as_json
  end

  def to_s
    "Part #{part}, Class #{id}"
  end

  def ==(other)
    if other.is_a? Hash
      part == other[:part] && id == other[:id]
    else
      part == other.part && id == other.id
    end
  end
end
