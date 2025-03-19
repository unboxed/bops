# frozen_string_literal: true

module BopsApi
  module Application
    module Parsers
      class FeeParser < BaseParser
        def parse
          return {} if params.blank?

          {
            payment_amount: params[:payable],
            payment_reference: params.dig("reference", "govPay")
          }
        end
      end
    end
  end
end
