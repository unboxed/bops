# frozen_string_literal: true

class ReportingType < ApplicationRecord
  with_options presence: true do
    validates :code, uniqueness: true
    validates :categories, :description
  end

  with_options if: :prior_approval? do
    validates :code, format: {with: /\APA\d{1,2}\z/, message: :invalid_pa_code}
    validates :legislation, presence: true
  end

  with_options unless: :prior_approval? do
    validates :code, format: {with: /\AQ\d{2}\z/, message: :invalid_q_code}
  end

  with_options allow_blank: true do
    validates :guidance_link, url: true
  end

  before_destroy do
    if ApplicationType.reporting_type_used?(code)
      errors.add(:base, :used) and throw(:abort)
    end
  end

  class << self
    def by_code
      order(:code_prefix, :code_suffix)
    end

    def categories
      ApplicationType.categories.values
    end

    def category_menu
      categories.map(&method(:category_menu_item))
    end

    def for_category(category)
      where(categories_contains(normalize_category(category))).by_code
    end

    def for_codes(codes)
      where(code: Array.wrap(codes)).by_code
    end

    def human_category(category)
      I18n.t("odp.application_categories.#{category.underscore}")
    end

    private

    def categories_contains(category)
      arel_table[:categories].contains(category)
    end

    def category_menu_item(category)
      [category, human_category(category)]
    end

    def normalize_category(category)
      Array.wrap(category.dasherize).compact_blank
    end
  end

  def human_categories
    categories.map(&method(:human_category))
  end

  def categories=(values)
    super(Array.wrap(values).compact_blank)
  end

  def full_description
    "#{code} – #{description}"
  end

  def prior_approval?
    categories.include?("prior-approval")
  end

  private

  def human_category(category)
    self.class.human_category(category)
  end
end
