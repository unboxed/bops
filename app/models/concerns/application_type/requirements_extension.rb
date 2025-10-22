# frozen_string_literal: true

class ApplicationType < ApplicationRecord
  module RequirementsExtension
    def by_category(&block)
      hash = categories.map { |category| [category, []] }.to_h
      sort_by(&:description).each_with_object(hash) { |r, h| h[r.category] << r }

      if block_given?
        hash.each(&block)
      else
        hash
      end
    end

    def any?
      block_given? ? super : super(&:present?)
    end

    def none?
      block_given? ? super : super(&:blank?)
    end

    def has?(requirement)
      any? { |r| r.description == requirement.description }
    end

    private

    def categories
      LocalAuthority::Requirement::CATEGORIES
    end
  end
end
