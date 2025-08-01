# frozen_string_literal: true

module StatusTags
  class ConsistencyChecklistComponent < StatusTags::BaseComponent
    def initialize(consistency_checklist:)
      @consistency_checklist = consistency_checklist
      super(status:)
    end

    private

    attr_reader :consistency_checklist

    def status
      if consistency_checklist.blank?
        :optional
      elsif consistency_checklist.in_assessment?
        :in_progress
      else
        :complete
      end
    end
  end
end
