# frozen_string_literal: true

module BopsSubmissions
  module Parsers
    class FeeParser < BaseParser
      def parse
        return {} if params.blank?
        case source
        when "Planning Portal"
          parse_planning_portal
        when "PlanX"
          parse_planx
        end
      end

      private

      def parse_planning_portal
        {
          payment_amount: params.dig("calculation", "payment", "amountDue"),
          payment_reference: params.dig("calculation", "payment", "paymentRef")
        }
      end

      def parse_planx
        {
          payment_amount: params[:payable],
          payment_reference: params.dig("reference", "govPay")
        }
      end
    end
  end
end
