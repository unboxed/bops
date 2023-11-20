# frozen_string_literal: true

class ApplicationType < ApplicationRecord
  NAME_ORDER = %w[prior_approval planning_permission lawfulness_certificate].freeze

  default_scope { in_order_of(:name, NAME_ORDER).order(:name) }

  has_many :planning_applications, dependent: :restrict_with_exception

  validates :name, presence: true

  def full_name
    name.humanize
  end

  def human_name
    I18n.t("application_types.#{name}")
  end

  def legislation_link
    fetch_legislation_translation("link")
  end

  def legislation_link_text
    fetch_legislation_translation("link_text")
  end

  def legislation_description
    fetch_legislation_translation("description")
  end

  def consultation?
    steps.include?("consultation")
  end

  def assessor_remarks
    assessment_details.excluding("past_applications")
  end

  def document_tag_list
    document_tags.values.flatten
  end

  def document_evidence_tags
    document_tags["evidence"]
  end

  def document_plan_tags
    document_tags["plans"]
  end

  class << self
    def menu(scope = all)
      scope.order(name: :asc).select(:name, :id).map do |application_type|
        [application_type.full_name, application_type.id]
      end
    end
  end

  private

  def part_and_section
    "#{part}#{section}"
  end

  def fetch_legislation_translation(key)
    I18n.t("application_types.legislation.#{name}.#{part_and_section}.#{key}", default: false)
  end
end
