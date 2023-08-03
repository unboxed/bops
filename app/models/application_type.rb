# frozen_string_literal: true

class ApplicationType < ApplicationRecord
  NAME_ORDER = %w[prior_approval lawfulness_certificate].freeze

  default_scope { in_order_of(:name, NAME_ORDER).order(:name) }

  has_many :planning_applications, dependent: :restrict_with_exception

  validates :name, presence: true

  def full_name
    name.humanize
  end

  def human_name
    I18n.t("application_types.#{name}")
  end

  class << self
    def menu(scope = all)
      scope.order(name: :asc).select(:name, :id).map do |application_type|
        [application_type.full_name, application_type.id]
      end
    end
  end
end
