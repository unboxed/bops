# frozen_string_literal: true

class DrawingNumbersListForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_reader :drawings

  def initialize(drawings, drawings_numbers_hash = {})
    @drawings = drawings.map { |drawing| DrawingNumbersUpdateForm.new(drawing) }
    @drawings_numbers_hash = drawings_numbers_hash
  end

  def update_all
    ActiveRecord::Base.transaction do
      drawings.each do |drawing|
        drawing.numbers = drawings_numbers_hash.dig(drawing.id.to_s, "numbers")
        drawing.save
      end

      if drawings.any? { |d| d.errors.present? }
        errors.add(:base, :missing_numbers)
        raise ActiveRecord::Rollback
      end
    end

    errors.none?
  end

  private

    attr_accessor :drawings_numbers_hash

    class DrawingNumbersUpdateForm
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :drawing

      validates :numbers, presence: { message: "Provide at least one number" }

      delegate *Drawing.attribute_names, to: :drawing

      def initialize(drawing)
        @drawing = drawing
      end

      def plan
        drawing.plan
      end

      def name
        drawing.name
      end

      def numbers=(value)
        drawing.numbers = value
      end

      def numbers
        drawing.numbers
      end

      def save
        if valid?
          @drawing.update(numbers: numbers)
        end

        errors.none?
      end
    end
end
