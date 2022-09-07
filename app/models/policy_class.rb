# frozen_string_literal: true

class PolicyClass < ApplicationRecord
  belongs_to :planning_application
  has_many :policies, dependent: :destroy

  accepts_nested_attributes_for :policies

  validates :name, :part, :section, :schedule, presence: true

  class << self
    def all_parts
      # NOTE: we might do multiple schedules at some point in the
      # future but no need to worry about it now
      I18n.t("schedules").first[:parts]
    end

    def classes_for_part(part)
      all_parts[part.to_i][:classes].map do |attributes|
        PolicyClass.new(attributes)
      end
    end
  end

  %w[in_assessment does_not_comply complies].each do |potential_status|
    define_method("#{potential_status}?") do
      status == potential_status.tr("_", " ")
    end
  end

  def status
    return "in assessment" if policies.to_be_determined.any?
    return "does not comply" if policies.does_not_comply.any?

    "complies"
  end

  def as_json(_options = nil)
    attributes.as_json
  end

  def to_s
    "Part #{part}, Class #{section}"
  end

  def ==(other)
    if other.is_a? Hash
      part == other[:part] && id == other[:id]
    else
      part == other.part && id == other.id
    end
  end
end
