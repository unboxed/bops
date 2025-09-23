# frozen_string_literal: true

module BopsCore
  module Notify
    class LetterForm < BaseForm
      attribute :address, :string
      attribute :heading, :string
      attribute :message, :string

      validates :address, :heading, :message, presence: true

      validate do
        if address_lines.size < 3
          errors.add :address, :too_short
        end

        if address_lines.size > 7
          errors.add :address, :too_long
        end
      end

      delegate :letter_template_id, to: :local_authority

      def check
        super do
          @response = client.send_letter(
            template_id: letter_template_id,
            reference: reference,
            personalisation: {
              address_line_1: address_line_1,
              address_line_2: address_line_2,
              address_line_3: address_line_3,
              address_line_4: address_line_4,
              address_line_5: address_line_5,
              address_line_6: address_line_6,
              address_line_7: address_line_7,
              heading: heading,
              message: message
            }
          )
        end
      end

      private

      def address_lines
        @address_lines ||= address.to_s.each_line.map(&:chomp).compact_blank
      end

      7.times do |i|
        define_method :"address_line_#{i + 1}" do
          address_lines[i].presence
        end
      end
    end
  end
end
