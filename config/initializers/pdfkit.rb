# frozen_string_literal: true

if system("which xvfb-run > /dev/null 2>&1")
  PDFKit.configure do |config|
    config.use_xvfb = true
  end
end
