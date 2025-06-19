# frozen_string_literal: true

require "csv"

class PlanningApplicationsImportService
  VALIDATION_REPORT_PATH = Rails.root.join("tmp/validation_report.csv")
  IMPORT_REPORT_PATH = Rails.root.join("tmp/import_results.csv")

  REQUIRED_COLUMNS = [
    "address_1", "agent_first_name", "agent_last_name", "applicant_first_name", "applicant_last_name",
    "assessment_in_progress_at", "awaiting_determination_at", "cil_liable", "decision", "description",
    "determination_date", "determined_at", "expiry_date", "invalidated_at", "valid_ownership_certificate",
    "parish_name", "payment_amount", "postcode", "previous_references", "received_at", "reference",
    "reporting_type_code", "returned_at", "target_date", "town", "uprn", "valid_description",
    "in_committee_at", "ownership_certificate_checked", "regulation_3", "regulation_4", "valid_fee",
    "valid_red_line_boundary", "validated_at", "ward", "withdrawn_at", "application_type"
  ].freeze

  attr_reader :csv_path, :local_authority_name

  def initialize(csv_path:, local_authority_name:, application_type:)
    @csv_path = Rails.root.join(csv_path)
    @local_authority_name = local_authority_name.downcase
    @application_type = application_type
    @import_report_rows = []
  end

  def run
    validate
    import
    report
  end

  def validate
    broadcast "Validating CSV at #{csv_path}..."

    csv = CSV.read(csv_path, headers: true)
    headers = csv.headers

    missing_columns = REQUIRED_COLUMNS.reject { |col| headers.include?(col) }
    blank_columns = headers.select do |header|
      csv.map { |row| row[header].to_s.strip }.all?(&:empty?)
    end

    issues = []
    issues << "Missing required columns: #{missing_columns.join(", ")}" if missing_columns.any?
    issues << "Columns with no data: #{blank_columns.join(", ")}" if blank_columns.any?

    CSV.open(VALIDATION_REPORT_PATH, "w") do |output|
      output << ["row_number", "previous_references", "blank_fields"]
      csv.each_with_index do |row, index|
        blank_fields = row.headers.select { |field| row[field].to_s.strip.empty? }
        next if blank_fields.empty?

        output << [
          index + 2,
          row["previous_references"].to_s.strip.presence || "(none)",
          blank_fields.join(", ")
        ]
      end
    end

    broadcast "Validation report written to: #{VALIDATION_REPORT_PATH}"

    if issues.any?
      issues.each { |msg| broadcast msg }
      broadcast "CSV validation completed with issues, continuing import."
    else
      broadcast "CSV validation passed — all required fields present and populated."
    end
  end

  def import
    broadcast "Importing PlanningApplications from #{csv_path} with local_authority_name #{local_authority_name}..."

    CSV.foreach(csv_path, headers: true) do |row|
      import_row(row)
    end

    broadcast "Import complete."
  end

  def report
    CSV.open(IMPORT_REPORT_PATH, "w") do |output|
      output << ["previous_references", "new_reference"]
      @import_report_rows.each { |r| output << r }
    end

    broadcast "Import results written to: #{IMPORT_REPORT_PATH}"
  end

  def import_row(row)
    app = PlanningApplicationCreationService.new(
      row.to_h,
      local_authority: local_authority,
      application_type: @application_type
    ).perform

    @import_report_rows << [row["previous_references"], app.reference]
  end

  def local_authority
    @local_authority ||= LocalAuthority.find_by!(subdomain: local_authority_name)
  end

  private

  def broadcast(message)
    Rails.logger.info(message)
    Rails.logger.debug(message)
  end
end
