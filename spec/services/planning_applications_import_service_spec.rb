# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationsImportService, type: :service do
  let(:csv_path) { "tmp/test_import.csv" }

  let(:local_authority) { create(:local_authority, :southwark) }
  let(:application_type) { create(:application_type, local_authority_id: local_authority.id) }
  let(:local_authority_name) { "Southwark" }

  subject(:service) do
    described_class.new(
      csv_path: csv_path,
      local_authority_name: local_authority_name,
      application_type: application_type
    )
  end

  let(:valid_headers) do
    described_class::REQUIRED_COLUMNS
  end

  let(:valid_row) do
    valid_headers.map { |h| [h, "value for #{h}"] }.to_h.merge(
      "decision" => "GRANT",
      "previous_references" => "PP-HH-123"
    )
  end

  before do
    # Write test CSV with headers and one valid row
    CSV.open(csv_path, "w") do |csv|
      csv << valid_headers
      csv << valid_headers.map { |h| valid_row[h] }
    end
  end

  after do
    [csv_path, described_class::VALIDATION_REPORT_PATH, described_class::IMPORT_REPORT_PATH].each do |path|
      File.delete(path) if File.exist?(path)
    end
  end

  describe "#validate" do
    it "creates a validation report file with no critical issues" do
      service.validate
      expect(File).to exist(described_class::VALIDATION_REPORT_PATH)

      rows = CSV.read(described_class::VALIDATION_REPORT_PATH, headers: true)
      expect(rows.headers).to include("row_number", "previous_references", "blank_fields")
    end
  end

  describe "#import" do
    it "creates a PlanningApplication with transformed decision" do
      expect {
        service.import
      }.to change(PlanningApplication, :count).by(1)

      expect(PlanningApplication.last.decision).to eq("granted")
    end

    it "adds local_authority_id and application_type_id" do
      service.import
      app = PlanningApplication.last

      expect(app.local_authority_id).to eq(local_authority.id)
      expect(app.application_type_id).to eq(application_type.id)
    end
  end

  describe "#report" do
    it "writes a mapping of previous_references to new references" do
      service.import
      service.report

      report_rows = CSV.read(described_class::IMPORT_REPORT_PATH, headers: true)
      expect(report_rows.length).to eq(1)
      expect(report_rows[0]["previous_references"]).to eq("PP-HH-123")
      expect(report_rows[0]["new_reference"]).to eq(PlanningApplication.last.reference)
    end
  end

  describe "#run" do
    it "runs validation, import, and report" do
      expect {
        service.run
      }.to change(PlanningApplication, :count).by(1)

      expect(File).to exist(described_class::VALIDATION_REPORT_PATH)
      expect(File).to exist(described_class::IMPORT_REPORT_PATH)
    end
  end
end
