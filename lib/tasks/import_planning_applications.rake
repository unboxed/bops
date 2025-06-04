# frozen_string_literal: true

require "csv"

VALIDATION_REPORT_PATH = Rails.root.join("lib/assets/data/validation_report.csv")
IMPORT_REPORT_PATH = Rails.root.join("lib/assets/data/import_results.csv")
REQUIRED_COLUMNS = ["address_1", "agent_first_name", "agent_last_name", "applicant_first_name", "applicant_last_name", "assessment_in_progress_at", "awaiting_determination_at", "cil_liable", "decision", "description", "determination_date", "determined_at", "expiry_date", "invalidated_at", "valid_ownership_certificate", "parish_name", "payment_amount", "postcode", "previous_references", "received_at", "reference", "reporting_type_code", "returned_at", "target_date", "town", "uprn", "valid_description", "in_committee_at", "ownership_certificate_checked", "regulation_3", "regulation_4", "valid_fee", "valid_red_line_boundary", "validated_at", "ward", "withdrawn_at", "payment_amount", "application_type"].freeze

namespace :import do
  def broadcast(message)
    puts message
    Rails.logger&.info(message)
  end

  desc "Pre-validate planning application CSV"
  task prevalidate: :environment do
    # We need to update this to work with Google Sheets API so we can work with PII within safe area
    csv_path = ENV["CSV"]
    unless csv_path
      broadcast "Usage: rake import:prevalidate CSV=path/to/file.csv"
      exit 1
    end

    broadcast "Validating CSV at #{csv_path}..."

    csv = CSV.read(Rails.root.join(csv_path), headers: true)
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
            index + 2, # account for 1-based row numbering, +1 for headers
            row["previous_references"].to_s.strip.presence || "(none)",
            blank_fields.join(", ")
          ]
        end
      end
    end

    broadcast "Validation report written to: #{VALIDATION_REPORT_PATH}"

    if issues.any?
      issues.each { |msg| broadcast msg }
      broadcast "CSV validation completed with issues, but continuing import."
    else
      broadcast "CSV validation passed — all required fields present and populated."
    end
  end

  # Need to add logic to halt import if the validation doesn't pass. Also need to tidy up agent name and company

  desc "Import planning applications from CSV with local_authority_id"
  task planning_applications: :environment do
    csv_path = ENV["CSV"]
    authority_id = ENV["AUTHORITY_ID"]

    unless csv_path && authority_id
      broadcast "Usage: rake import:planning_applications CSV=path/to/file.csv AUTHORITY_ID=123"
      exit 1
    end

    # Run pre-validation but do not block import
    Rake::Task["import:prevalidate"].invoke

    broadcast "Importing PlanningApplications from #{csv_path} with local_authority_id #{authority_id}..."

    import_report_rows = []

    CSV.foreach(Rails.root.join(csv_path), headers: true) do |row|
      attrs = row.to_h

      # Transform known decision values
      case attrs["decision"]&.strip&.upcase
      when "GRANT"
        attrs["decision"] = "granted"
      when "REFUSED"
        attrs["decision"] = "refused"
      when "NOT REQUIRED"
        attrs["decision"] = "not_required"
      end

      # Added email, regulation_3, regulation_4 and application_type as a placeholder just to see if the import works
      app = PlanningApplication.create!(
        attrs.merge(
          local_authority_id: authority_id,
          application_type_id: 872,
          regulation_3: "pending",
          regulation_4: "pending",
          applicant_email: attrs["applicant_email"].presence || "admin@example.com",
          ownership_certificate_checked: attrs["ownership_certificate_checked"].presence || false
        )
      )

      import_report_rows << [row["previous_references"], app.reference]
    end

    CSV.open(IMPORT_REPORT_PATH, "w") do |output|
      output << ["previous_references", "new_reference"]
      import_report_rows.each { |r| output << r }
    end

    broadcast "Import complete."
    broadcast "Import results written to: #{IMPORT_REPORT_PATH}"
  end
end
