# frozen_string_literal: true

module Enforcements
  class DocumentPresenter
    include BopsCore::Presentable
    include GovukComponentsHelper

    presents :document
    attr_reader :document

    def initialize(document)
      @document = document
    end

    def source
      document.metadata["source"] || document.user&.name || "Unknown"
    end

    def type
      case document.owner&.class
      when Enforcement, Submission
        :submission
      else
        :other
      end
    end

    def type_tag_colour
      case type
      when :submission
        "blue"
      when :evidence
        "green"
      when :communication
        "yellow"
      when :site_visit
        "orange"
      else
        "grey"
      end
    end
  end
end
