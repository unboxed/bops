# frozen_string_literal: true

require "zip"
require "uri"
require "faraday"

module BopsSubmissions
  class ZipExtractionService
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10

    def initialize(submission:)
      @submission = submission
    end

    def call
      io = open_io(document_link_url)
      Zip::InputStream.new(io).tap do |zip_io|
        while (entry = zip_io.get_next_entry)
          next if entry.name.end_with?("/")  # skip directories
          content = zip_io.read
          handle_file(entry.name, content)
        end
      end
    ensure
      # clean up the Tempfile if used
      io.close! if io.respond_to?(:close!)
    end

    private

    def document_link_url
      @submission
        .request_body.fetch("documentLinks", [])
        .first.fetch("documentLink")
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

    # Stream the remote ZIP into a Tempfile using Faraday
    def download_via_faraday(url)
      tf = Tempfile.new([@submission.external_uuid || "bops", ".zip"])
      tf.binmode

      conn = Faraday.new do |f|
        f.response :raise_error            # 4xx/5xx raise exceptions
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
      case File.extname(name).downcase
      when ".pdf", ".docx"
        attach_to_submission(name, content)
      when ".json"
        @submission.update!(json_file: JSON.parse(content))
      else
        @submission.metadata[:other_files] ||= []
        @submission.metadata[:other_files] << {name: name}
        @submission.save!
      end
    end

    def attach_to_submission(filename, data)
      io = StringIO.new(data)
      doc = @submission.documents.build
      doc.file.attach(
        io: io,
        filename: filename,
        content_type: Marcel::MimeType.for(filename),
        identify: false
      )
      doc.save!
    end
  end
end
