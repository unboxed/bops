# frozen_string_literal: true

module StatusTags
  class LetterComponent < StatusTags::BaseComponent
    def initialize(status:)
      @status = status
      super(status:)
    end
  end
end
