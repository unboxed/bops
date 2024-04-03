# frozen_string_literal: true

class ReportingType < ApplicationRecord
  enum :category, ApplicationType.categories

  with_options presence: true do
    validates :code, uniqueness: true
    validates :category, :description
  end

  with_options if: :prior_approval? do
    validates :code, format: { with: /\APA\d{1,2}\z/, message: :invalid_pa_code }
    validates :legislation, presence: true
  end

  with_options unless: :prior_approval? do
    validates :code, format: { with: /\AQ\d{2}\z/, message: :invalid_q_code }
  end

  with_options allow_blank: true do
    validates :guidance_link, url: true
  end

  class << self
    def by_code
      order(:code)
    end

    def for_category(category)
      where(category: category).order(:code)
    end

    def for_codes(codes)
      where(code: Array.wrap(codes)).order(:code)
    end
  end

  def full_description
    "#{code} – #{description}"
  end
end
