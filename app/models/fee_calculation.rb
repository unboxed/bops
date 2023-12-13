# frozen_string_literal: true

class FeeCalculation
  attr_reader :payable_fee, :total_fee, :exemptions, :reductions

  class << self
    def from_odp_data(odp_data)
      calc = FeeCalculation.new
      calc.payable_fee = odp_data[:payable]
      calc.total_fee = odp_data[:calculated]
      calc.exemptions = odp_data[:exemption]&.select { |k, v| v }&.keys
      calc.reductions = odp_data[:reduction]&.select { |k, v| v }&.keys

      calc
    end

    def from_planx_data(planx_data)
      planx_passport_data = planx_data.dig(:planx_debug_data, :passport, :data)

      return FeeCalculation.new if planx_passport_data.blank?

      exemption = planx_passport_data&.select { |k, v|
        k.to_s.start_with? "application.fee.exemption"
      }&.map { |k, v| [k.to_s.split(".").last.to_sym, v.first == "true"] }.to_h
      reduction = planx_passport_data&.select { |k, v|
        k.to_s.start_with? "application.fee.reduction"
      }&.map { |k, v| [k.to_s.split(".").last.to_sym, v.first == "true"] }.to_h

      from_odp_data({
        payable: planx_passport_data[:"application.fee.payable"],
        calculated: planx_passport_data[:"application.fee.calculated"],
        exemption:,
        reduction:
      })
    end

    def from_planning_portal_data(pp_data)
      from_odp_data({
        payable: pp_data[:calculation][:payment][:amountDue],
        calculated: pp_data[:fullFee][:fee],
        exemption: pp_data[:concessions][:exemptions],
        reduction: pp_data[:concessions][:reductions]  # TODO make names match ODP?
      })
    end
  end
end
