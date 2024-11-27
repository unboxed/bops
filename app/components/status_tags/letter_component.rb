# frozen_string_literal: true

module StatusTags
  class LetterComponent < StatusTags::BaseComponent
    def initialize(status:)
      @status = status&.to_sym || :error
      raise "Invalid status `#{@status.inspect}'" unless NeighbourLetter::STATUSES.values.map(&:to_sym).include?(@status) || @status == :new

      super
    end

    def link_text
      t("status_tag_component.letter_status.#{status}")
    end

    def colour
      return "red" if NeighbourLetter::FAILURE_STATUSES.include? status

      case status.to_sym
      when :new
        "blue"
      when :posted
        "light-blue"
      when :submitted
        "yellow"
      when :printing
        "purple"
      end
    end
  end
end
