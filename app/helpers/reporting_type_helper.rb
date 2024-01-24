# frozen_string_literal: true

module ReportingTypeHelper
  def reporting_types(application_type)
    I18n.t(application_type, scope: :reporting_type).flat_map do |type, information|
      [information.values]
    end
  end
end
