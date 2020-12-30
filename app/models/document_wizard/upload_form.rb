# frozen_string_literal: true

module DocumentWizard
  class UploadForm < BaseForm
    attr_accessor :file

    validates :file, presence: { message: "Please choose a file" }
    validates :tags, presence: { message: "Please select one or more tags" }

    def initialize(document_attributes = {})
      super

      @file = document_attributes[:file]
    end
  end
end
