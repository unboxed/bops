# frozen_string_literal: true

module StatusTags
  class PreappComponent < BaseComponent
    private

    def status
      return :supported if @status&.to_sym == :complies

      super
    end

    def colour
      return "green" if status == :supported

      super
    end
  end
end
