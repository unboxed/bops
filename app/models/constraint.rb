# frozen_string_literal: true

class Constraint < ApplicationRecord
  self.inheritance_column = "inheritance_type"

  validates :category, :type, presence: true
  validates :type, uniqueness: {scope: :local_authority}

  belongs_to :local_authority, optional: true

  has_many :planning_application_constraints, dependent: :destroy

  scope :options_for_local_authority, ->(local_authority_id) { where(local_authority_id: [local_authority_id, nil]) }

  alias_method :constraint_id, :id

  class << self
    def for_type(type)
      find_by(type: normalize_type(type))
    end

    def grouped_by_category(local_authority_id)
      options_for_local_authority(local_authority_id).group_by(&:category)
    end

    def non_applicable_constraints(applicable_constraints)
      all.reject do |constraint|
        applicable_constraints.pluck(:constraint_id).include?(constraint.id)
      end
    end

    def all_constraints(query)
      scope = order(:category)

      if query.blank?
        scope
      else
        scope.where(search_query, search_param(query))
      end
    end

    private

    def normalize_type(type)
      type.tr(".", "_").downcase
    end

    delegate :quote_column_name, to: :connection

    def search_query
      "#{quoted_table_name}.#{quote_column_name("search")} @@ to_tsquery('simple', ?)"
    end

    def search_param(query)
      query.to_s
        .scan(/[-\w]{3,}/)
        .map { |word| word.gsub(/^-/, "!") }
        .map { |word| word.gsub(/-$/, "") }
        .map { |word| word.gsub(/.+/, "\\0:*") }
        .join(" & ")
    end
  end

  def type_code
    I18n.t("constraint_type_codes.#{type}", default: type.titleize.capitalize)
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
end
