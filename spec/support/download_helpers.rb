# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    const_set(:DOWNLOADS_PATH, Rails.root.join("tmp/downloads"))

    def downloads_path
      self.class.const_get(:DOWNLOADS_PATH)
    end

    def downloaded_files
      wait_for_download && downloads
    end

    private

    def all_downloads
      Dir["*", base: downloads_path]
    end

    def download_in_progress?(file)
      File.extname(file) == ".crdownload"
    end

    def downloads
      all_downloads.reject(&method(:download_in_progress?))
    end

    def wait_for_download
      count = downloads.size

      Timeout.timeout(Capybara.default_max_wait_time) do
        sleep 0.1 until downloads.size > count
      end

      true
    end
  end

  config.include helpers, type: :system
end
