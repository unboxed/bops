# frozen_string_literal: true

module DocumentWizard
  class BaseForm
    include ActiveModel::Model

    attr_accessor :document

    delegate(*Document.attribute_names.map { |attr| [attr, "#{attr}="] }
        .flatten, to: :document)

    def initialize(document_attributes = {})
      @document = Document.new(document_attributes)
    end
  end
end
