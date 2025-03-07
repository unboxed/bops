# frozen_string_literal: true

class ApplicationType < ApplicationRecord
  belongs_to :local_authority
  belongs_to :config, autosave: true

  has_many :planning_applications, -> { kept }, dependent: :restrict_with_exception

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
