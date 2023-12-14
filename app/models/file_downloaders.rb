# frozen_string_literal: true

module FileDownloaders
  Downloaders = StoreModel.one_of do |json|
    const_get(json.fetch("type"))
  rescue KeyError, NameError
    raise ArgumentError, "Missing file downloader type"
  end

  class << self
    def to_type
      Downloaders.to_type
    end
  end
end
