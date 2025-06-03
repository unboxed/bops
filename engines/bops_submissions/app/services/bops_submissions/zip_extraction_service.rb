# frozen_string_literal: true

require "zip"
require "uri"
require "faraday"

module BopsSubmissions
  class ZipExtractionService
    OPEN_TIMEOUT = ENV.fetch("ZIP_OPEN_TIMEOUT", 10).to_i
    READ_TIMEOUT = ENV.fetch("ZIP_READ_TIMEOUT", 20).to_i

    ATTACHABLE_EXTENSIONS = %w[.pdf .docx .doc .jpg .jpeg .png].freeze
    APPLICATION_FILE = "Application.json"

    def initialize(submission:)
      @submission = submission
    end

    attr_reader :submission

    def call
      submission.document_link_urls.each do |url|
        extract_using_input_stream(url)
      rescue Zip::Error => e
        Rails.logger.warn "ZipExtractionService: InputStream failed for #{url}: #{e.message}, retrying with Zip::File"
        extract_using_zip_file(url)
      rescue => e
        Rails.logger.error "ZipExtractionService: Unexpected error for #{url}: #{e.class} #{e.message}"
        raise
      end
    end

    private

    def extract_using_input_stream(url)
      io = open_io_for_zip(url)
      Zip::InputStream.open(io) do |zip_io|
        while (entry = zip_io.get_next_entry)
          next if entry.name.end_with?("/")
          begin
            process_zip_entry_stream(entry.name, zip_io)
          rescue => e
            Rails.logger.warn "ZipExtractionService: Skipping entry #{entry.name} due to #{e.class}: #{e.message}"
            Appsignal.report_error(e)
            next
          end
        end
      end
    ensure
      safe_close(io)
    end

    def extract_using_zip_file(url)
      io_or_path = open_io_for_zip(url)
      Zip::File.open(io_or_path.path) do |zip|
        zip.each do |entry|
          next if entry.directory?
          begin
            process_zip_entry_file(entry)
          rescue => e
            Rails.logger.warn "ZipExtractionService: Skipping entry #{entry.name} due to #{e.class}: #{e.message}"
            Appsignal.report_error(e)
            next
          end
        end
      end
    ensure
      safe_close(io_or_path)
    end

    def open_io_for_zip(url)
      if File.exist?(url)
        File.open(url, "rb")
      else
        uri = URI.parse(url)
        case uri.scheme
        when "file"
          File.open(uri.path, "rb")
        when "http", "https"
          download_zip_to_tempfile(uri.to_s)
        else
          raise ArgumentError, "Unsupported URL scheme: #{uri.scheme}"
        end
      end
    end

    def download_zip_to_tempfile(url)
      tf = Tempfile.new([submission.external_uuid, ".zip"])
      tf.binmode

      conn = Faraday.new do |f|
        f.response :raise_error
        f.options.open_timeout = OPEN_TIMEOUT
        f.options.timeout = READ_TIMEOUT
      end

      conn.get(url) do |req|
        req.options.on_data = ->(chunk, _bytes_so_far, _env) { tf.write(chunk) }
      end

      tf.rewind
      tf
    rescue Faraday::Error => e
      tf&.close!
      raise "Failed to download ZIP from #{url}: #{e.message}"
    end

    def process_zip_entry_stream(entry_name, zip_io)
      Tempfile.open(["zip_entry", File.extname(entry_name)]) do |temp|
        temp.binmode
        IO.copy_stream(zip_io, temp)
        temp.rewind
        process_entry(entry_name, temp)
      end
    end

    def process_zip_entry_file(entry)
      entry_name = entry.name
      entry.get_input_stream.tap do |stream|
        Tempfile.open(["zip_entry", File.extname(entry_name)]) do |temp|
          temp.binmode
          IO.copy_stream(stream, temp)
          temp.rewind
          process_entry(entry_name, temp)
        end
      end
    end

    def process_entry(name, io)
      ext = File.extname(name).downcase
      if ATTACHABLE_EXTENSIONS.include?(ext)
        attach_to_submission(name, io)
      elsif name == APPLICATION_FILE
        update_json_file(io)
      else
        store_other_file(name)
      end
    end

    def update_json_file(io)
      content = io.read
      submission.update!(json_file: JSON.parse(content))
    end

    def store_other_file(name)
      payload = submission.application_payload || {}
      payload["other_files"] ||= []
      payload["other_files"] << {"name" => name}
      submission.update!(application_payload: payload)
    end

    def attach_to_submission(filename, io)
      document = submission.documents.build(metadata: {filename: filename})
      document.file.attach(
        io: io,
        filename: filename,
        content_type: Marcel::MimeType.for(filename)
      )
      document.save!
    rescue => e
      document.assign_attributes(metadata: document.metadata.merge(error: e.message))
      document.save!
    end

    def safe_close(io_object)
      return unless io_object
      if io_object.is_a?(Tempfile)
        io_object.close!
      elsif io_object.respond_to?(:close)
        io_object.close
      end
    rescue => e
      Rails.logger.warn "ZipExtractionService: Error closing IO: #{e.message}"
    end
  end
end
