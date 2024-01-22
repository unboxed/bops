# frozen_string_literal: true

class FeeCalculation < ApplicationRecord
  include Auditable

  belongs_to :planning_application
  delegate :audits, to: :planning_application

  after_update :audit_updated!
  after_create :audit_updated!

  class << self
    def from_odp_data(odp_data)
      FeeCalculation.new(
        payable_fee: odp_data[:payable],
        total_fee: odp_data[:calculated],
        exemptions: odp_data[:exemption]&.select { |k, v| v }&.keys,
        reductions: odp_data[:reduction]&.select { |k, v| v }&.keys
      )
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

  private

  def audit_updated!
    return unless saved_changes?

    saved_changes.keys.map do |attribute_name|
      next if saved_change_to_attribute(attribute_name).all? { |value| value.blank? || value.try(:zero?) }

      next if %w[created_at updated_at].include? attribute_name

      original_attribute = saved_change_to_attribute(attribute_name).first
      new_attribute = saved_change_to_attribute(attribute_name).second

      audit_comment = if %w[payable_fee total_fee requested_fee].include? attribute_name
        "Changed from: £#{format("%.2f",
          original_attribute.to_f)} \r\n Changed to: £#{format("%.2f", new_attribute.to_f)}"
      else
        "Changed from: #{original_attribute} \r\n Changed to: #{new_attribute}"
      end

      audit!(activity_type: "updated",
        activity_information: attribute_name.humanize,
        audit_comment: audit_comment)
    end
  end
end
