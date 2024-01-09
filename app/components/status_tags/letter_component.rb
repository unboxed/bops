# frozen_string_literal: true

module StatusTags
  class LetterComponent < StatusTags::BaseComponent
    def initialize(status:)
      @status = status
    end

    attr_reader :status

    private

    def task_list?
      false
    end
  end
end
