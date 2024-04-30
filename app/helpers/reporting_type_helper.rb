# frozen_string_literal: true

module ReportingTypeHelper
  def reporting_radio_button_disabled?(status, params)
    status.reporting_type_status == :complete && params.blank?
  end
end
