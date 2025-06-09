# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class FeeParser < BaseParser
      def parse
        return {} if params.blank?

        {
          payment_amount: params.dig("calculation", "payment", "amountDue"),
          payment_reference: params.dig("calculation", "payment", "paymentRef")
        }
      end
    end
  end
end
