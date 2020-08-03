# frozen_string_literal: true

module DrawingWizard
  class ConfirmUploadForm < BaseForm
    attr_accessor :confirmation
    attr_accessor :plan

    validates :confirmation, presence: {
      message: "Please select one of the below options"
    }

    def initialize(drawing_attributes = {})
      @confirmation = drawing_attributes.delete(:confirmation)
      @plan = drawing_attributes[:plan]

      super
    end

    def confirmed?
      @confirmation == "true"
    end
  end
end
