class DocumentAnalyserService
  require 'openai'
  require 'base64'

  def initialize(document)
    @document = document
    @client = OpenAI::Client.new(
      access_token: "xxx",
      # Optional: adjust if you need specific API settings
      request_timeout: 120
    )
  end

  def call
    return unless @document.file.attached?

    file_path = download_file
    return unless file_path

    description = generate_description(file_path)
    @document.update!(ai_description: description) if description.present?
  rescue StandardError => e
    Rails.logger.error "Error analyzing document #{@document.id}: #{e.message}"
    false
  ensure
    File.delete(file_path) if file_path && File.exist?(file_path)u   
  end

  private

  def download_file
    return unless @document.file.attached?

    # Create a temporary file with the original filename and extension
    temp_file = Tempfile.new([@document.file.filename.base, @document.file.filename.extension_with_delimiter], binmode: true)
    
    # Download the file locally in binary mode
    begin
      @document.file.blob.download do |chunk|
        temp_file.write(chunk.force_encoding("BINARY"))
      end
    rescue => e
      Rails.logger.error "Failed to download file: #{e.message}"
      return nil
    end
    
    temp_file.close
    temp_file.path
  end

  def generate_description(file_path)
    image_data = File.binread(file_path)
    base64_image = Base64.strict_encode64(image_data)

    response = @client.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "system",
            content: "You are an expert in analyzing architectural plans and drawings. Interpret both the visual elements and any text present in the image."
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "Provide a detailed description of this architectural plan or drawing. Include any text content (such as labels or dimensions) and describe visual features like layout, structure, and notable design elements."
              },
              {
                type: "image_url",
                image_url: { url: "data:image/jpeg;base64,#{base64_image}" }
              }
            ]
          }
        ],
        max_tokens: 300,
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")&.strip
  end
end
