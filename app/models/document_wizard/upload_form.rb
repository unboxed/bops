# frozen_string_literal: true

module DocumentWizard
  class UploadForm < BaseForm
    attr_accessor :plan

    validates :plan, presence: { message: "Please choose a file" }
    validates :tags, presence: { message: "Please select one or more tags" }

    def initialize(document_attributes = {})
      super

      @plan = document_attributes[:plan]
    end
  end
end
