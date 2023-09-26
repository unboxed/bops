# frozen_string_literal: true

class Constraint < ApplicationRecord
  self.inheritance_column = "inheritance_type"

  validates :category, :type, presence: true
  validates :type, uniqueness: { scope: :local_authority }

  belongs_to :local_authority, optional: true

  has_many :planning_application_constraints, dependent: :destroy

  scope :options_for_local_authority, ->(local_authority_id) { where(local_authority_id: [local_authority_id, nil]) }

  alias_method :constraint_id, :id

  def type_code
    if I18n.t("constraint_type_codes.#{type}").include?("translation missing")
      type.titleize.capitalize
    else
      I18n.t("constraint_type_codes.#{type}")
    end
  end

  def start_date
    nil
  end

  def description
    nil
  end

  def checked?
    false
  end

  class << self
    def grouped_by_category(local_authority_id)
      options_for_local_authority(local_authority_id).group_by(&:category)
    end

    def non_applicable_constraints(applicable_constraints)
      all.reject do |constraint|
        applicable_constraints.pluck(:constraint_id).include?(constraint.id)
      end
    end
  end
end
