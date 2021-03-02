require "mkmf"

if find_executable("xvfb-run")
  PDFKit.configure do |config|
    config.use_xvfb = true
  end
end
