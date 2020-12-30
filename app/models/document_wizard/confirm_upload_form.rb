# frozen_string_literal: true

module DocumentWizard
  class ConfirmUploadForm < BaseForm
    attr_accessor :confirmation
    attr_accessor :file

    validates :confirmation, presence: {
      message: "Please select one of the below options"
    }

    def initialize(document_attributes = {})
      @confirmation = document_attributes.delete(:confirmation)
      @file = document_attributes[:file]

      super
    end

    def confirmed?
      @confirmation == "true"
    end
  end
end
