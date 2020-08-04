# frozen_string_literal: true

module DrawingWizard
  class UploadForm < BaseForm
    attr_accessor :plan

    validates :plan, presence: { message: "Please choose a file" }
    validates :tags, presence: { message: "Please select one or more tags" }

    def initialize(drawing_attributes = {})
      super

      @plan = drawing_attributes[:plan]
    end
  end
end
