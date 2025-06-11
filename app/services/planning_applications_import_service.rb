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

  attr_reader :csv_path, :authority_id

  def initialize(csv_path:, authority_id:, application_type:)
    @csv_path = Rails.root.join(csv_path)
    @authority_id = authority_id
    @application_type = application_type
    @import_report_rows = []
  end

  def broadcast(message)
    Rails.logger.debug message
    Rails.logger&.info(message)
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

    unless missing_columns.empty?
      issues << "Missing required columns: #{missing_columns.join(", ")}"
    end

    unless blank_columns.empty?
      issues << "Columns with no data: #{blank_columns.join(", ")}"
    end

    CSV.open(VALIDATION_REPORT_PATH, "w") do |output|
      output << ["row_number", "previous_references", "blank_fields"]
      csv.each_with_index do |row, index|
        blank_fields = row.headers.select { |field| row[field].to_s.strip.empty? }

        if blank_fields.any?
          output << [
            index + 2, # 1-based row index + header
            row["previous_references"].to_s.strip.presence || "(none)",
            blank_fields.join(", ")
          ]
        end
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
    broadcast "Importing PlanningApplications from #{csv_path} with local_authority_id #{authority_id}..."

    CSV.foreach(csv_path, headers: true) do |row|
      attrs = row.to_h
      # Temporary solution until application_type is populated
      attrs.delete("application_type")

      # Transform decision values
      case attrs["decision"]&.strip&.upcase
      when "GRANT"
        attrs["decision"] = "granted"
      when "REFUSED"
        attrs["decision"] = "refused"
      when "NOT REQUIRED"
        attrs["decision"] = "not_required"
      end

      app = PlanningApplication.create!(
        attrs.merge(
          local_authority_id: authority_id,
          application_type_id: @application_type.id,
          regulation_3: "pending",
          regulation_4: "pending",
          applicant_email: attrs["applicant_email"].presence || "admin@example.com",
          ownership_certificate_checked: attrs["ownership_certificate_checked"].presence || false
        )
      )

      @import_report_rows << [row["previous_references"], app.reference]
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
end
