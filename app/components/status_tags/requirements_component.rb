# frozen_string_literal: true

module StatusTags
  class RequirementsComponent < StatusTags::BaseComponent
    def initialize(requirements:)
      @requirements = requirements
      super(status:)
    end

    private

    attr_reader :requirements

    def status
      :not_started
    end
  end
end
