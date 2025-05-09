# frozen_string_literal: true

module StatusTags
  class PreappComponent < BaseComponent
    private

    def status
      case @status&.to_sym
      when :complies
        :supported
      else
        super
      end
    end

    def colour
      case status&.to_sym
      when :supported
        "green"
      when :needs_changes
        "yellow"
      else
        super
      end
    end
  end
end
