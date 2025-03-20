# frozen_string_literal: true

class ApplicationType < ApplicationRecord
  belongs_to :local_authority
  belongs_to :config, autosave: true

  has_many :planning_applications, -> { kept }, dependent: :restrict_with_exception
  has_many :recommended_planning_applications,
    class_name: "PlanningApplication",
    foreign_key: :recommended_application_type_id,
    inverse_of: :recommended_application_type,
    dependent: :nullify

  self.ignored_columns += %i[
    part
    section
    assessment_details
    steps
    consistency_checklist
    document_tags
    features
    status
    configured
    category
    reporting_types
    decisions
  ]

  with_options on: :determination_period do
    validates :determination_period_days, presence: true
    validates :determination_period_days, numericality: {only_integer: true}
    validates :determination_period_days, numericality: {greater_than_or_equal_to: 1}
    validates :determination_period_days, numericality: {less_than_or_equal_to: 99}
  end

  class << self
    def by_name
      preload(:config).in_order_of(:name, Config::NAME_ORDER).order(:name, :code)
    end

    def active
      joins(:config).where(config: {status: "active"})
    end

    def menu(scope = by_name, type: nil)
      scope = scope.where(name: type) if type
      scope.active.order(code: :asc).map do |application_type|
        [application_type.description, application_type.id]
      end
    end
  end

  def respond_to_missing?(name, include_private = false)
    config.respond_to?(name, include_private)
  end

  def method_missing(name, ...)
    config.public_send(name, ...)
  end

  %i[
    determination_period_in_days
  ].each do |name|
    define_method name do
      super || config.public_send(name)
    end
  end
end
