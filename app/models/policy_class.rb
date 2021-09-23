# frozen_string_literal: true

class PolicyClass
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id
  attribute :name
  attribute :part
  attribute :policies
  attribute :url

  class << self
    def all_parts
      # NOTE: we might do multiple schedules at some point in the
      # future but no need to worry about it now
      I18n.t("schedules").first[:parts]
    end

    def classes_for_part(number)
      all_parts[number.to_i][:classes]
        .map { |h| PolicyClass.new(h) }
        .each { |c| c.stamp_part!(number) }
    end
  end

  def stamp_part!(number)
    self.part = number
  end

  def stamp_status!
    policies.each do |policy|
      policy["status"] = "to_be_determined"
    end
  end

  def status
    return "in assessment" if policies.any? { |p| p["status"] == "to_be_determined" }
    return "does not comply" if policies.any? { |p| p["status"] == "does_not_comply" }

    "complies"
  end

  def as_json(_options = nil)
    attributes.as_json
  end

  def to_s
    "Part #{part}, Class #{id}"
  end

  # NOTE: this is a method that is normally provided and overriden in
  # the scope of ActiveRecord. Since this is an ActiveModel, stick to
  # the naming and call it manually from the controller; it joins the
  # part and the ID of the policy class together, since we store them
  # flat on PlanningApplication and thus we cannot distinguish them on
  # their IDs alone.
  def to_param
    [part, id].join("-")
  end

  def ==(other)
    if other.is_a? Hash
      part == other[:part] && id == other[:id]
    else
      part == other.part && id == other.id
    end
  end
end
