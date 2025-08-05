# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe BopsSubmissions::ZipExtractionService, type: :service do
  let!(:zip_file) do
    file = Tempfile.new(["test_zip", ".zip"])
    Zip::OutputStream.open(file.path) do |zos|
      zos.put_next_entry("Application.json")
      zos.write json_data.to_json

      zos.put_next_entry("valid.pdf")
      zos.write "%PDF-1.4 dummy content"

      zos.put_next_entry("valid.png")
      zos.write "\x89PNG\r\n\x1a\nfakepng"

      zos.put_next_entry("valid.jpg")
      zos.write "\xFF\xD8\xFFfakejpg"

      zos.put_next_entry("notes.txt")
      zos.write "some text"
    end
    file.flush
    file
  end

  let(:zip_path) { zip_file.path }

  let(:submission) do
    create(
      :submission,
      request_body: {
        "documentLinks" => [{"documentLink" => zip_path}]
      }
    )
  end

  let(:json_data) { {"foo" => "bar"} }

  let(:service) { described_class.new(submission:) }
  subject(:call_service) { service.call }

  context "when all attachments succeed" do
    it "parses JSON, attaches PDF, and stores other_files" do
      expect { call_service }.not_to raise_error
      submission.reload

      expect(submission.json_file).to eq(json_data)
      expect(submission.application_payload["other_files"]).to eq([{"name" => "notes.txt"}])

      docs = submission.documents.order(:created_at)
      filenames = docs.map { |d| d.metadata["filename"] }
      expect(filenames).to match_array(%w[valid.pdf valid.png valid.jpg])

      docs.each do |doc|
        expect(doc.file).to be_attached
        expect(doc.metadata["error"]).to be_nil
      end
    end
  end

  context "when the PDF attachment is invalid" do
    before do
      allow_any_instance_of(ActiveStorage::Attached::One)
        .to receive(:attach)
        .and_wrap_original do |orig, *args|
          options = args.first
          if options[:filename] == "valid.pdf"
            raise StandardError, "invalid PDF format"
          else
            orig.call(*args)
          end
        end
    end

    it "still creates error-only record for PDF, and attaches PNG/JPG" do
      expect { call_service }.not_to raise_error
      submission.reload

      expect(submission.json_file).to eq(json_data)
      expect(submission.application_payload["other_files"]).to eq([{"name" => "notes.txt"}])

      docs = submission.documents.order(:created_at)
      filenames = docs.map { |d| d.metadata["filename"] }
      expect(filenames).to match_array(%w[valid.pdf valid.png valid.jpg])

      pdf_doc = docs.find { |d| d.metadata["filename"] == "valid.pdf" }
      expect(pdf_doc.file).not_to be_attached
      expect(pdf_doc.metadata["error"]).to eq("invalid PDF format")

      png_doc = docs.find { |d| d.metadata["filename"] == "valid.png" }
      expect(png_doc.file).to be_attached
      expect(png_doc.metadata["error"]).to be_nil

      jpg_doc = docs.find { |d| d.metadata["filename"] == "valid.jpg" }
      expect(jpg_doc.file).to be_attached
      expect(jpg_doc.metadata["error"]).to be_nil
    end
  end

  context "when downloading via Faraday" do
    let(:fake_submission) { Struct.new(:external_uuid).new("abc123") }
    let(:service) { described_class.new(submission: fake_submission) }
    let(:url) { "http://example.com/my.zip" }

    let(:zip_data) do
      buf = Tempfile.new(["remote", ".zip"])
      Zip::OutputStream.open(buf.path) do |zos|
        zos.put_next_entry("foo.txt")
        zos.write "hello!"
      end
      raw = File.binread(buf.path)
      raw.force_encoding(Encoding::ASCII_8BIT)
    end

    before do
      stub_request(:get, url)
        .to_return(
          status: 200,
          body: zip_data,
          headers: {"Content-Type" => "application/zip"}
        )
    end

    it "streams the remote zip into a Tempfile and returns it" do
      tf = service.send(:download_zip_to_tempfile, url)
      expect(tf).to be_a(Tempfile)

      downloaded = File.binread(tf.path).force_encoding(Encoding::ASCII_8BIT)
      expect(downloaded).to eq(zip_data)

      tf.close!
    end

    it "bubbles Faraday::TimeoutError when the remote hangs" do
      allow_any_instance_of(Faraday::Connection)
        .to receive(:get)
        .and_raise(Faraday::TimeoutError)

      expect {
        service.send(:download_zip_to_tempfile, url)
      }.to raise_error("Failed to download ZIP from http://example.com/my.zip: timeout")
    end
  end

  shared_examples "a real planning portal fixture" do |zip_name:, doc_count:, expected_filenames:|
    let(:zip_path) { zip_fixture("applications/#{zip_name}.zip") }
    let(:application_json) { json_fixture("files/applications/#{zip_name}.json") }
    let(:submission) do
      create(
        :submission,
        request_body: {
          "documentLinks" => [{"documentLink" => zip_path}]
        }
      )
    end

    it "processes #{zip_name}.zip with no errors" do
      expect { service.call }.not_to raise_error
      submission.reload

      expect(submission.json_file.deep_symbolize_keys).to eq(application_json.deep_symbolize_keys)

      expect(submission.application_payload["other_files"]).to eq([{"name" => "Application.xml"}])

      docs = submission.documents.order(:created_at)
      expect(docs.size).to eq(doc_count)

      actual = docs.map { |d| d.metadata["filename"] }
      expect(actual).to match_array(expected_filenames)

      docs.each do |doc|
        expect(doc.file).to be_attached
        expect(doc.metadata["error"]).to be_nil
      end
    end
  end

  [
    {
      zip_name: "PT-10087984",
      doc_count: 9,
      expected_filenames: [
        "Test document DH.pdf",
        "Test document DH.docx",
        "C.jpg",
        "ApplicationForm.pdf",
        "AttachmentSummary.pdf",
        "ApplicationFormRedacted.pdf",
        "FeeCalculation.pdf",
        "Community Infrastructure Levy - Completed form_included_in_Additional plans.pdf",
        "The location plan_included_in_Additional plans.pdf"
      ]
    },
    {
      zip_name: "PT-10078243",
      doc_count: 9,
      expected_filenames: [
        "10078243_DRAFT.pdf",
        "AmendmentSummary.pdf",
        "ApplicationForm.pdf",
        "ApplicationFormRedacted.pdf",
        "AttachmentSummary.pdf",
        "FeeCalculation.pdf",
        "Test PP jpg.jpg",
        "TestPP pdf.pdf",
        "TestPP.docx"
      ]
    },
    {
      zip_name: "PT-10079425",
      doc_count: 8,
      expected_filenames: [
        "ApplicationForm.pdf",
        "ApplicationFormRedacted.pdf",
        "AttachmentSummary.pdf",
        "Community Infrastructure Levy - Completed form_included_in_Detail Drawing.pdf",
        "FeeCalculation.pdf",
        "doc_Test_2.doc",
        "docx_Test_1.docx",
        "2857827.jpg"
      ]
    }
  ].each do |params|
    context "with the #{params[:zip_name]}.zip real planning portal fixture" do
      include_examples "a real planning portal fixture", **params
    end
  end

  describe "zip processing method" do
    context "when Zip::InputStream throws error and fallbacks to Zip::File" do
      let(:zip_name) { "PT-10078243" }
      let(:zip_path) { zip_fixture("applications/#{zip_name}.zip") }
      let(:submission) { create(:submission, request_body: {"documentLinks" => [{"documentLink" => zip_path}]}) }

      before do
        allow(service).to receive(:extract_using_input_stream).with(zip_path).and_raise(
          Zip::GPFBit3Error,
          "General purpose flag Bit 3 is set so not possible to get proper info from local header." \
          "Please use ::Zip::File instead of ::Zip::InputStream"
        )
        allow(service).to receive(:extract_using_zip_file).and_call_original
        allow(Rails.logger).to receive(:warn)
      end

      it "rescues the Zip::Error and calls extract_using_zip_file instead" do
        expect { service.call }.not_to raise_error
        expect(service).to have_received(:extract_using_zip_file).with(zip_path).once

        expect(Rails.logger)
          .to have_received(:warn)
          .with(/ZipExtractionService: InputStream failed for .*: General purpose flag Bit 3 is set so not possible.*retrying with Zip::File/)

        expect(submission.reload.documents).not_to be_empty
      end
    end

    context "when using Zip::InputStream" do
      let(:zip_name) { "PT-10079425" }
      let(:zip_path) { zip_fixture("applications/#{zip_name}.zip") }
      let(:submission) do
        create(:submission,
          request_body: {"documentLinks" => [{"documentLink" => zip_path}]})
      end

      before do
        allow(service).to receive(:extract_using_input_stream).and_call_original
      end

      it "uses Zip::InputStream and never hits the fallback" do
        expect(service).to receive(:extract_using_input_stream).with(zip_path).once.and_call_original
        expect(service).not_to receive(:extract_using_zip_file)

        service.call

        expect(submission.reload.documents).not_to be_empty
      end
    end
  end

  it "raises ArgumentError for unsupported URI schemes" do
    submission = create(:submission, request_body: {"documentLinks" => [{"documentLink" => "ftp://example.com/test.zip"}]})
    service = described_class.new(submission: submission)
    expect { service.call }.to raise_error(ArgumentError, /Unsupported URL scheme/)
  end

  context "when Application.json contains invalid JSON" do
    let!(:zip_file) do
      file = Tempfile.new(["bad_json", ".zip"])
      Zip::OutputStream.open(file.path) do |zos|
        zos.put_next_entry("Application.json")
        zos.write "not { valid: json }"

        zos.put_next_entry("valid.pdf")
        zos.write "%PDF-1.4 dummy content"
      end
      file.flush
      file
    end

    let(:zip_path) { zip_file.path }
    let(:submission) do
      create(
        :submission,
        request_body: {"documentLinks" => [{"documentLink" => zip_path}]}
      )
    end

    it "reports the JSON::ParserError to AppSignal, logs a warning, and still attaches other files" do
      allow(Appsignal).to receive(:report_error)
      allow(Rails.logger).to receive(:warn)

      expect { call_service }.not_to raise_error

      expect(Appsignal).to have_received(:report_error).once do |arg|
        expect(arg).to be_a(JSON::ParserError)
        expect(arg.message).to match(/unexpected token 'not' at line 1 column 1/)
      end

      expect(Rails.logger).to have_received(:warn).with(
        /ZipExtractionService: Skipping entry Application.json due to JSON::ParserError: unexpected token 'not' at line 1 column 1/
      )

      expect(submission.reload.json_file).to be_nil

      docs = submission.reload.documents
      expect(docs.count).to eq(1)
      expect(docs.first.metadata["filename"]).to eq("valid.pdf")
      expect(docs.first.file).to be_attached
    end
  end

  context "when ZIP has no entries" do
    let!(:empty_zip) do
      file = Tempfile.new(["empty", ".zip"])
      Zip::OutputStream.open(file.path) {}
      file.flush
      file
    end
    let(:submission) { create(:submission, request_body: {"documentLinks" => [{"documentLink" => empty_zip.path}]}) }

    it "leaves submission.json_file and documents untouched" do
      expect { call_service }.not_to raise_error
      submission.reload
      expect(submission.json_file).to be_nil
      expect(submission.documents).to be_empty
      expect(submission.application_payload["other_files"]).to be_blank
    end
  end

  context "when ZIP contains only unsupported file types" do
    let!(:zip_file) do
      file = Tempfile.new(["unsupported_ext", ".zip"])
      Zip::OutputStream.open(file.path) do |zos|
        zos.put_next_entry("notes.txt")
        zos.write "plain text"
      end
      file.flush
      file
    end

    let(:submission) { create(:submission, request_body: {"documentLinks" => [{"documentLink" => zip_file.path}]}) }

    it "does not create any attachments but stores the filename under other_files" do
      expect { call_service }.not_to raise_error
      submission.reload
      expect(submission.json_file).to be_nil
      expect(submission.documents).to be_empty
      expect(submission.application_payload["other_files"]).to eq([{"name" => "notes.txt"}])
    end
  end
end
