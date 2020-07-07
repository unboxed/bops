# frozen_string_literal: true

module DrawingWizard
  class BaseForm
    include ActiveModel::Model

    attr_accessor :drawing

    delegate *Drawing.attribute_names.map { |attr| [attr, "#{attr}="] }.
        flatten, to: :drawing

    def initialize(drawing_attributes = {})
      @drawing = Drawing.new(drawing_attributes)
    end
  end
end
