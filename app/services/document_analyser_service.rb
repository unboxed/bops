require "openai"
require "base64"

class DocumentAnalyserService
  attr_reader :document, :client

  def initialize(document)
    @document = document
    @client = OpenAI::Client.new(
      access_token: "XXX",
      request_timeout: 120
    )
  end

  def call
    return unless document.file.attached?

    file_path = download_file
    return unless file_path

    image = build_image(file_path)
    user_content = user_message(image)

    ai_summary = generate_ai_summary(user_content)

    document.update!(ai_summary: ai_summary) if ai_summary.present?
  rescue StandardError => e
    Rails.logger.error("Error analysing the document with id: #{document.id}: #{e.message}")
    false
  end

  private

  def download_file
    # Create a temporary file with the original filename and extension
    temp_file = Tempfile.new([document.file.filename.base, document.file.filename.extension_with_delimiter], binmode: true)

    # Download the file locally in binary mode
    begin
      document.file.blob.download do |chunk|
        temp_file.write(chunk.force_encoding("BINARY"))
      end
    rescue => e
      Rails.logger.error "Failed to download file: #{e.message}"
      return nil
    end

    temp_file.close
    temp_file.path
  end

  def build_image(file_path)
    image_data = File.binread(file_path)
    base64_image = Base64.strict_encode64(image_data)
  end

  def generate_ai_summary(user_content)    
    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { 
            role: "system", 
            content: "You are an expert, with experience in UK housing/planning, in interpreting and extracting a concise summary/description of a document" 
          },
          {
            role: "user",
            content: user_content
          }
        ]
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  def user_message(base64_image)
    [
      {
        type: "text",
        text: "Analyse this image/document and provide a short description/summary of its content in no more than 2 sentences."    
      },
      {
        type: "image_url",
        image_url: { 
          url: "data:image/jpeg;base64,#{base64_image}"
        }
      }
    ]
  end
end
