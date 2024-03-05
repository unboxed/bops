# frozen_string_literal: true

class HeadsOfTerm < ApplicationRecord
  module TermsExtension
    def standard
      standard_heads_of_terms.map do |term|
        detect { |c| c.title == term.title } || term
      end
    end

    def other
      all - all.select { |term| standard_heads_of_terms.map(&:title).include? term.title }
    end

    private

    def standard_heads_of_terms
      I18n.t(:heads_of_terms_list).map { |k, v| Term.new(v) }
    end
  end
end
