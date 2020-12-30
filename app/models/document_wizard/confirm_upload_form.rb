# frozen_string_literal: true

module DocumentWizard
  class ConfirmUploadForm < BaseForm
    attr_accessor :confirmation
    attr_accessor :plan

    validates :confirmation, presence: {
      message: "Please select one of the below options"
    }

    def initialize(document_attributes = {})
      @confirmation = document_attributes.delete(:confirmation)
      @plan = document_attributes[:plan]

      super
    end

    def confirmed?
      @confirmation == "true"
    end
  end
end
