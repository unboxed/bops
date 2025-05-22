# frozen_string_literal: true

require "zip"
require "uri"
require "faraday"

module BopsSubmissions
  class ZipExtractionService
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 20

    ATTACHABLE_EXTENSIONS = %w[.pdf .docx .doc .jpg .jpeg .png].freeze
    APPLICATION_FILE = "Application.json"

    def initialize(submission:)
      @submission = submission
    end

    attr_reader :submission

    def call
      submission.document_link_urls.each do |url|
        process_with_zip_input_stream(url)
      rescue Zip::Error => e
        Rails.logger.warn "Zip::InputStream failed (#{e.message}), falling back to Zip::File"
        process_with_zip_file(url)
      end
    end

    private

    def process_with_zip_input_stream(url)
      io = open_io(url)
      Zip::InputStream.new(io).tap do |zip_io|
        while (entry = zip_io.get_next_entry)
          next if entry.name.end_with?("/")
          content = zip_io.read
          handle_file(entry.name, content)
        end
      end
    ensure
      io&.close! if io.respond_to?(:close!)
    end

    def process_with_zip_file(url)
      io_or_path = open_io(url)
      Zip::File.open(io_or_path.path) do |zip|
        zip.each do |entry|
          next if entry.directory?
          handle_file(entry.name, entry.get_input_stream.read)
        end
      end
    ensure
      io_or_path.close! if io_or_path.is_a?(Tempfile)
    end

    def open_io(url)
      if url.start_with?("/")
        File.open(url, "rb")
      else
        uri = URI.parse(url)
        case uri.scheme
        when "file"
          File.open(uri.path, "rb")
        when "http", "https"
          download_via_faraday(uri.to_s)
        else
          raise ArgumentError, "Unsupported URL scheme: #{uri.scheme}"
        end
      end
    end

    def download_via_faraday(url)
      tf = Tempfile.new([submission.external_uuid, ".zip"])
      tf.binmode

      conn = Faraday.new do |f|
        f.response :raise_error
        f.options.open_timeout = OPEN_TIMEOUT
        f.options.timeout = READ_TIMEOUT
      end

      conn.get(url) do |req|
        req.options.on_data = lambda do |chunk, _bytes_so_far, _env|
          tf.write(chunk)
        end
      end

      tf.rewind
      tf
    end

    def handle_file(name, content)
      ext = File.extname(name).downcase

      if ATTACHABLE_EXTENSIONS.include?(ext)
        attach_to_submission(name, content)
      elsif name == APPLICATION_FILE
        submission.update!(json_file: JSON.parse(content))
      else
        submission.application_payload[:other_files] ||= []
        submission.application_payload[:other_files] << {name: name}
        submission.save!
      end
    end

    def attach_to_submission(filename, data)
      io = StringIO.new(data)
      begin
        document = submission.documents.build(metadata: {filename: filename})
        document.file.attach(
          io: io,
          filename: filename,
          content_type: Marcel::MimeType.for(filename),
          identify: false
        )
        document.save!
      rescue => e
        document.assign_attributes(metadata: document.metadata.merge(error: e.message))
        document.save!
      end
    end
  end
end
